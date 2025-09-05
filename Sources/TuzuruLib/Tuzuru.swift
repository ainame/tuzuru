import Foundation
import Markdown
import Mustache

public struct Tuzuru: Sendable {
    private let sourceLoader: SourceLoader
    private let markdownProcessor: MarkdownProcessor
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper

    public init(
        fileManager: FileManagerWrapper,
        configuration: BlogConfiguration,
    ) throws {
        sourceLoader = SourceLoader(configuration: configuration, fileManager: fileManager)
        markdownProcessor = MarkdownProcessor()
        self.configuration = configuration
        self.fileManager = fileManager
    }

    public func loadSources(_: BlogSourceLayout) async throws -> RawSource {
        try await sourceLoader.loadSources()
    }

    public func processContents(_ rawSource: RawSource) async throws -> Source {
        let processor = markdownProcessor
        let processedPosts = try await withThrowingTaskGroup(of: Post.self) { group in
            for rawPost in rawSource.posts {
                group.addTask {
                    try processor.process(rawPost)
                }
            }

            var processedPosts = [Post]()
            for try await processedPost in group {
                processedPosts.append(processedPost)
            }
            return processedPosts
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
        let blogGenerator = try BlogGenerator(configuration: configuration, fileManager: fileManager)
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

    public static func initializeBlog(fileManager: FileManagerWrapper) async throws {
        // Check if tuzuru.json already exists
        let path = fileManager.workingDirectory
        let configPath = path.appending("tuzuru.json")
        if fileManager.fileExists(atPath: configPath) {
            throw TuzuruError.configurationAlreadyExists
        }

        // Generate and write tuzuru.json
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let configData = try encoder.encode(BlogConfiguration.default)
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
            print("Updated existing .gitignore")
        } else {
            // Create new .gitignore with common OS files and Tuzuru-specific ones
            let defaultGitignoreContent = """
                .DS_Store

                # Tuzuru
                .build/
                blog/
                """
            try defaultGitignoreContent.write(to: URL(fileURLWithPath: gitignorePath.string), atomically: true, encoding: .utf8)
            print("Created .gitignore with common OS files and Tuzuru ignore patterns")
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

        let importer = BlogImporter(fileManager: fileManager)
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

        for post in source.posts {
            let requestPath = "/" + pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted)
            mapping[requestPath] = post.path
        }

        // Add index page mapping
        mapping["/"] = configuration.sourceLayout.contents.appending("index.html")
        mapping["/index.html"] = configuration.sourceLayout.contents.appending("index.html")

        return mapping
    }

    public func shouldRegenerate(
        requestPath: String,
        lastRequestTime: Date,
        pathMapping: [String: FilePath]
    ) -> Bool {
        let changeDetector = ChangeDetector(fileManager: fileManager, configuration: configuration)
        return changeDetector.checkIfChangesMade(at: requestPath, since: lastRequestTime, in: pathMapping)
    }


    public func regenerate() async throws -> Source {
        let rawSource = try await loadSources(configuration.sourceLayout)
        let processedSource = try await processContents(rawSource)
        let blogGenerator = try BlogGenerator(configuration: configuration, fileManager: fileManager)
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
