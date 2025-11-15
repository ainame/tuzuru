import Foundation
import Logging
import Markdown
import Mustache

public struct Tuzuru: Sendable {
    /// Maximum number of concurrent tasks for both git operations and markdown processing
    /// Limited to processor count minus 1 to leave headroom for system processes
    public static let maxConcurrency = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)

    private let sourceLoader: SourceLoader
    private let markdownProcessor: MarkdownProcessor
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper
    private let logger: Logger

    public init(
        fileManager: FileManagerWrapper,
        configuration: BlogConfiguration,
        logger: Logger
    ) throws {
        sourceLoader = SourceLoader(configuration: configuration, fileManager: fileManager)
        markdownProcessor = MarkdownProcessor()
        self.configuration = configuration
        self.fileManager = fileManager
        self.logger = logger
    }

    public func loadSources(_: BlogSourceLayout) async throws -> RawSource {
        try await sourceLoader.loadSources()
    }

    public func processContents(_ rawSource: RawSource) async throws -> Source {
        let processor = markdownProcessor

        // Use SharedIterator for controlled concurrency (CPU-bound work)
        let iterator = SharedIterator(rawSource.posts.makeIterator())

        let processedPosts = try await withThrowingTaskGroup(of: [Post].self) { group in
            for _ in 0..<Self.maxConcurrency {
                group.addTask { [iterator] in
                    var results: [Post] = []
                    while let rawPost = await iterator.next() {
                        let post = try processor.process(rawPost)
                        results.append(post)
                    }
                    return results
                }
            }

            // Collect results from all workers
            var allPosts: [Post] = []
            for try await workerResults in group {
                allPosts.append(contentsOf: workerResults)
            }
            return allPosts
        }

        // Create processed Source with the same metadata and templates
        return Source(
            metadata: rawSource.metadata,
            templates: rawSource.templates,
            posts: processedPosts,
            years: rawSource.years,
            categories: rawSource.categories
        )
    }

    public func generate(_ source: Source) async throws -> FilePath {
        let blogGenerator = try BlogGenerator(
            configuration: configuration,
            fileManager: fileManager,
            logger: logger
        )
        return try blogGenerator.generate(source)
    }

    // MARK: - Static Configuration Methods

    public static func loadConfiguration(from path: String?) throws -> BlogConfiguration {
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let loader = BlogConfigurationLoader(fileManager: fileManager)
        return try loader.load(from: path)
    }

    public static func createDefaultConfiguration() -> BlogConfiguration {
        return BlogConfiguration.default
    }

    // MARK: - Initialization Methods

    public static func initializeBlog(
        fileManager: FileManagerWrapper,
        logger: Logger
    ) async throws {
        // Check if tuzuru.json already exists
        let path = fileManager.workingDirectory
        let configPath = path.appending("tuzuru.json")
        if fileManager.fileExists(atPath: configPath) {
            throw TuzuruError.configurationAlreadyExists
        }

        // Generate and write tuzuru.json with only metadata
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let simplifiedConfig = ["metadata": BlogConfiguration.default.metadata]
        let configData = try encoder.encode(simplifiedConfig)
        try configData.write(to: URL(fileURLWithPath: configPath.string))

        // Copy template and asset files from bundle
        let bundle = try TuzuruResources.resourceBundle(fileManager: fileManager)
        let initializer = BlogInitializer(fileManager: fileManager, bundle: bundle)

        let templatesDir = path.appending("templates")
        try initializer.copyTemplateFiles(to: templatesDir)

        let assetsDir = path.appending("assets")
        try initializer.copyAssetFiles(to: assetsDir)

        // Handle .gitignore file
        let gitignorePath = path.appending(".gitignore")

        if fileManager.fileExists(atPath: gitignorePath) {
            // Append to existing .gitignore
            let existingContent = try String(contentsOf: URL(fileURLWithPath: gitignorePath.string), encoding: .utf8)
            let updatedContent = existingContent + "\n# Added by Tuzuru\n.build/\nblog\n"
            try updatedContent.write(to: URL(fileURLWithPath: gitignorePath.string), atomically: true, encoding: .utf8)
            logger.info("Updated existing .gitignore")
        } else {
            // Create new .gitignore with common OS files and Tuzuru-specific ones
            let defaultGitignoreContent = """
                .DS_Store

                # Tuzuru
                .build/
                blog/
                """
            try defaultGitignoreContent.write(to: URL(fileURLWithPath: gitignorePath.string), atomically: true, encoding: .utf8)
            logger.info("Created .gitignore with common OS files and Tuzuru ignore patterns")
        }

        // Create directory structure
        let directories = [
            path.appending("contents"),
            path.appending("contents/unlisted"),
        ]

        for directory in directories {
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Import Methods

    public func importFiles(from sourcePath: String, to destinationPath: String, dryRun: Bool = false) async throws -> ImportResult {
        let options = BlogImporter.ImportOptions(
            sourcePath: sourcePath,
            destinationPath: destinationPath
        )

        let importer = BlogImporter(fileManager: fileManager, logger: logger)
        let result = try await importer.importFiles(options: options, dryRun: dryRun)
        return ImportResult(
            importedCount: result.importedCount,
            skippedCount: result.skippedCount,
            errorCount: result.errorCount,
        )
    }

    // MARK: - Path Generation Methods

    public func generateDisplayPaths(for source: Source) -> [String] {
        let pathGenerator = PathGenerator(
            configuration: configuration.output,
            contentsBasePath: configuration.sourceLayout.contents,
            unlistedBasePath: configuration.sourceLayout.unlisted
        )

        return source.posts.map { post in
            pathGenerator.generateOutputPath(for: post.path, isUnlisted: post.isUnlisted)
        }
    }

    // MARK: - Auto-regeneration Methods

    public func createPathMapping(for source: Source) -> [String: FilePath] {
        let pathGenerator = PathGenerator(
            configuration: configuration.output,
            contentsBasePath: configuration.sourceLayout.contents,
            unlistedBasePath: configuration.sourceLayout.unlisted
        )

        var mapping: [String: FilePath] = [:]

        // Map individual posts to their source files
        for post in source.posts {
            let requestPath = "/" + pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted)
            mapping[requestPath] = post.path
        }

        // For auto-generated pages, use a special marker to indicate they depend on the contents directory
        let contentsDirectory = configuration.sourceLayout.contents

        // Index page - depends on all posts
        mapping["/"] = contentsDirectory
        mapping["/index.html"] = contentsDirectory

        // Year pages - depend on all posts from that year
        for year in source.years {
            mapping["/\(year)/"] = contentsDirectory
            mapping["/\(year)/index.html"] = contentsDirectory
        }

        // Category pages - depend on all posts with that category
        for category in source.categories {
            mapping["/\(category)/"] = contentsDirectory.appending(category)
            mapping["/\(category)/index.html"] = contentsDirectory.appending(category)
        }

        return mapping
    }

    public func shouldRegenerate(
        requestPath: String,
        lastRequestTime: Date,
        pathMapping: [String: FilePath]
    ) -> Bool {
        let changeDetector = ChangeDetector(fileManager: fileManager, configuration: configuration, logger: logger)
        return changeDetector.checkIfChangesMade(at: requestPath, since: lastRequestTime, in: pathMapping)
    }

    public func regenerate() async throws -> Source {
        let rawSource = try await loadSources(configuration.sourceLayout)
        let processedSource = try await processContents(rawSource)
        let blogGenerator = try BlogGenerator(
            configuration: configuration,
            fileManager: fileManager,
            logger: logger
        )
        _ = try blogGenerator.generate(processedSource)
        return processedSource
    }

    // MARK: - Amend Methods

    public func amendFile(
        filePath: String,
        newDate: String? = nil,
        newAuthor: String? = nil,
        fileManager: FileManager = .default
    ) async throws {
        let amender = FileAmender(configuration: configuration, fileManager: self.fileManager)
        try await amender.amendFile(filePath: FilePath(filePath), newDate: newDate, newAuthor: newAuthor)
    }

}

extension Tuzuru {
    public struct ImportResult: Sendable {
        public let importedCount: Int
        public let skippedCount: Int
        public let errorCount: Int
    }
}
