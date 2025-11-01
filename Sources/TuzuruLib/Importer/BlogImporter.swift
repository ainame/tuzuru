import Foundation
import Logging

/// Handles importing Hugo/Jekyll markdown files with YAML front matter to Tuzuru format
struct BlogImporter {
    struct ImportOptions {
        let sourcePath: String
        let destinationPath: String
    }

    struct ImportResult {
        let importedCount: Int
        let skippedCount: Int
        let errorCount: Int
    }

    private let fileManager: FileManagerWrapper
    private let parser = YAMLFrontMatterParser()
    private let transformer = MarkdownTransformer()
    private let shortcodeProcessor = HugoShortcodeProcessor()
    private let gitCommitter: GitCommitter
    private let logger: Logger

    init(fileManager: FileManagerWrapper, logger: Logger) {
        self.fileManager = fileManager
        self.gitCommitter = GitCommitter(workingDirectory: fileManager.workingDirectory)
        self.logger = logger
    }

    /// Imports markdown files from source directory to destination
    /// - Parameters:
    ///   - options: Import configuration options
    ///   - dryRun: If true, no files will be modified
    /// - Returns: ImportResult with counts of imported, skipped, and error files
    func importFiles(options: ImportOptions, dryRun: Bool = false) async throws -> ImportResult {
        let sourceDir = FilePath(options.sourcePath)
        let destinationDir = FilePath(options.destinationPath)

        // Validate source directory
        guard fileManager.fileExists(atPath: sourceDir) else {
            throw ImportError.sourceDirectoryNotFound(options.sourcePath)
        }

        // Create destination directory if needed
        if !dryRun {
            try fileManager.createDirectory(atPath: destinationDir, withIntermediateDirectories: true)
        }

        // Find markdown files
        let markdownFiles = try findMarkdownFiles(in: sourceDir)

        if markdownFiles.isEmpty {
            logger.info("📝 No markdown files found in \(options.sourcePath)")
            return ImportResult(importedCount: 0, skippedCount: 0, errorCount: 0)
        }

        logger.info("🔍 Found \(markdownFiles.count) markdown file(s) to import")

        if dryRun {
            logger.info("🔬 DRY RUN - No files will be modified")
        }

        var importedCount = 0
        var skippedCount = 0
        var errorCount = 0

        // Process each file
        for markdownFile in markdownFiles {
            do {
                let success = try await processFile(
                    sourcePath: markdownFile,
                    destinationDir: destinationDir,
                    options: options,
                    dryRun: dryRun
                )

                if success {
                    importedCount += 1
                } else {
                    skippedCount += 1
                }
            } catch {
                errorCount += 1
                logger.error("❌ Error processing \(markdownFile.lastComponent?.string ?? markdownFile.string): \(error.localizedDescription)")
            }
        }

        return ImportResult(importedCount: importedCount, skippedCount: skippedCount, errorCount: errorCount)
    }

    // MARK: - Private Methods

    private func findMarkdownFiles(in directory: FilePath) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []

        let enumerator = fileManager.enumerator(atPath: directory)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().hasSuffix(".md") || file.lowercased().hasSuffix(".markdown") {
                markdownFiles.append(directory.appending(file))
            }
        }

        return markdownFiles.sorted { $0.string < $1.string }
    }

    private func processFile(
        sourcePath: FilePath,
        destinationDir: FilePath,
        options: ImportOptions,
        dryRun: Bool
    ) async throws -> Bool {
        // Read source file
        guard let sourceData = fileManager.contents(atPath: sourcePath),
              let sourceContent = String(data: sourceData, encoding: .utf8) else {
            throw ImportError.cannotReadFile(sourcePath.string)
        }

        // Parse YAML front matter
        let parseResult = try parser.parse(sourceContent)

        // Validate required metadata
        guard let title = parseResult.metadata.title else {
            logger.info("⏭️  Skipping \(sourcePath.lastComponent?.string ?? sourcePath.string): No title in front matter")
            return false
        }

        // Parse date if available
        var publicationDate: Date?
        if let dateString = parseResult.metadata.date {
            publicationDate = parser.parseDate(dateString)
            if publicationDate == nil {
                logger.warning("⚠️  Could not parse date '\(dateString)' for \(title)")
            }
        }

        // Generate destination filename
        let sourceFilename = sourcePath.lastComponent?.string ?? "imported.md"
        let destinationPath = destinationDir.appending(sourceFilename)

        // Check if destination file already exists
        if !dryRun && fileManager.fileExists(atPath: destinationPath) {
            logger.warning("⚠️  File already exists: \(destinationPath.string)")
            throw ImportError.destinationFileExists(destinationPath.string)
        }

        // Process Hugo shortcodes first, then transform content
        let contentWithProcessedShortcodes = shortcodeProcessor.processShortcodes(in: parseResult.content)
        let transformedContent = transformer.transform(content: contentWithProcessedShortcodes, title: title)

        if dryRun {
            let dateStr = publicationDate.map { " (\(ISO8601DateFormatter().string(from: $0)))" } ?? ""
            logger.info("📝 Would import: \(title)\(dateStr) -> \(destinationPath.lastComponent?.string ?? destinationPath.string)")
            return true
        }

        // Write transformed file
        try transformedContent.write(toFile: destinationPath.string, atomically: true, encoding: .utf8)

        // Create git commit
        let commitDate = publicationDate ?? Date()
        let author = parseResult.metadata.author.map { "\($0) <imported@tuzuru.local>" }
        let commitMessage = gitCommitter.generateImportCommitMessage(
            title: title,
            originalDate: commitDate
        )

        try await gitCommitter.commit(
            filePath: destinationPath,
            message: commitMessage,
            date: commitDate,
            author: author
        )

        let dateStr = publicationDate.map { " (\(ISO8601DateFormatter().string(from: $0)))" } ?? ""
        logger.info("✅ Imported: \(title)\(dateStr) -> \(destinationPath.lastComponent?.string ?? destinationPath.string)")

        return true
    }
}

enum ImportError: Error, LocalizedError, Sendable {
    case sourceDirectoryNotFound(String)
    case cannotReadFile(String)
    case destinationFileExists(String)
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .sourceDirectoryNotFound(let path):
            return "Source directory not found: \(path)"
        case .cannotReadFile(let path):
            return "Cannot read file: \(path)"
        case .destinationFileExists(let path):
            return "Destination file already exists: \(path)"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}
