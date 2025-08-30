import Foundation

/// Handles importing Hugo/Jekyll markdown files with YAML front matter to Tuzuru format
public struct BlogImporter: Sendable {
    private let parser = YAMLFrontMatterParser()
    private let transformer = MarkdownTransformer()
    private let gitCommitter = GitCommitter()
    
    public struct ImportOptions: Sendable {
        public let sourcePath: String
        public let destinationPath: String
        public let skipGit: Bool
        public let verbose: Bool
        
        public init(sourcePath: String, destinationPath: String, skipGit: Bool = false, verbose: Bool = false) {
            self.sourcePath = sourcePath
            self.destinationPath = destinationPath
            self.skipGit = skipGit
            self.verbose = verbose
        }
    }
    
    public struct ImportResult: Sendable {
        public let importedCount: Int
        public let skippedCount: Int
        public let errorCount: Int
        
        public init(importedCount: Int, skippedCount: Int, errorCount: Int) {
            self.importedCount = importedCount
            self.skippedCount = skippedCount
            self.errorCount = errorCount
        }
    }
    
    public init() {}
    
    /// Imports markdown files from source directory to destination
    /// - Parameters:
    ///   - options: Import configuration options
    ///   - dryRun: If true, no files will be modified
    /// - Returns: ImportResult with counts of imported, skipped, and error files
    public func importFiles(options: ImportOptions, dryRun: Bool = false) async throws -> ImportResult {
        let fileManager = FileManager.default
        let sourceDir = FilePath(options.sourcePath)
        let destinationDir = FilePath(options.destinationPath)
        
        // Validate source directory
        guard fileManager.fileExists(atPath: sourceDir.string) else {
            throw ImportError.sourceDirectoryNotFound(options.sourcePath)
        }
        
        // Create destination directory if needed
        if !dryRun {
            try fileManager.createDirectory(atPath: destinationDir.string, withIntermediateDirectories: true)
        }
        
        // Check git repository status
        let isGitRepo = await gitCommitter.isGitRepository()
        if !options.skipGit && !isGitRepo && !dryRun {
            if options.verbose {
                print("⚠️  Not a git repository. Initializing git repository...")
            }
            try await gitCommitter.initializeRepository()
        }
        
        // Find markdown files
        let markdownFiles = try findMarkdownFiles(in: sourceDir, fileManager: fileManager)
        
        if markdownFiles.isEmpty {
            if options.verbose {
                print("📝 No markdown files found in \(options.sourcePath)")
            }
            return ImportResult(importedCount: 0, skippedCount: 0, errorCount: 0)
        }
        
        if options.verbose {
            print("🔍 Found \(markdownFiles.count) markdown file(s) to import")
        }
        
        if dryRun {
            print("🔬 DRY RUN - No files will be modified")
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
                    fileManager: fileManager,
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
                print("❌ Error processing \(markdownFile.lastComponent?.string ?? markdownFile.string): \(error.localizedDescription)")
                if options.verbose {
                    print("   Detail: \(error)")
                }
            }
        }
        
        return ImportResult(importedCount: importedCount, skippedCount: skippedCount, errorCount: errorCount)
    }
    
    // MARK: - Private Methods
    
    private func findMarkdownFiles(in directory: FilePath, fileManager: FileManager) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []
        
        let enumerator = fileManager.enumerator(atPath: directory.string)
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
        fileManager: FileManager,
        options: ImportOptions,
        dryRun: Bool
    ) async throws -> Bool {
        // Read source file
        guard let sourceData = fileManager.contents(atPath: sourcePath.string),
              let sourceContent = String(data: sourceData, encoding: .utf8) else {
            throw ImportError.cannotReadFile(sourcePath.string)
        }
        
        // Parse YAML front matter
        let parseResult = try parser.parse(sourceContent)
        
        // Validate required metadata
        guard let title = parseResult.metadata.title else {
            if options.verbose {
                print("⏭️  Skipping \(sourcePath.lastComponent?.string ?? sourcePath.string): No title in front matter")
            }
            return false
        }
        
        // Parse date if available
        var publicationDate: Date? = nil
        if let dateString = parseResult.metadata.date {
            publicationDate = parser.parseDate(dateString)
            if publicationDate == nil && options.verbose {
                print("⚠️  Could not parse date '\(dateString)' for \(title)")
            }
        }
        
        // Generate destination filename
        let sourceFilename = sourcePath.lastComponent?.string ?? "imported.md"
        let destinationPath = destinationDir.appending(sourceFilename)
        
        // Check if destination file already exists
        if !dryRun && fileManager.fileExists(atPath: destinationPath.string) {
            if options.verbose {
                print("⚠️  File already exists: \(destinationPath.string)")
            }
            throw ImportError.destinationFileExists(destinationPath.string)
        }
        
        // Transform content
        let transformedContent = transformer.transform(content: parseResult.content, title: title)
        
        if options.verbose {
            print("📝 Processing: \(title)")
            if let date = publicationDate {
                print("   📅 Original date: \(DateFormatter.shortDate.string(from: date))")
            }
            print("   📄 Source: \(sourcePath.string)")
            print("   📄 Destination: \(destinationPath.string)")
        }
        
        if dryRun {
            print("📝 Would import: \(title) -> \(destinationPath.lastComponent?.string ?? destinationPath.string)")
            return true
        }
        
        // Write transformed file
        try transformedContent.write(toFile: destinationPath.string, atomically: true, encoding: .utf8)
        
        // Create git commit if enabled
        if !options.skipGit {
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
        }
        
        if !options.verbose {
            print("✅ Imported: \(title)")
        }
        
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