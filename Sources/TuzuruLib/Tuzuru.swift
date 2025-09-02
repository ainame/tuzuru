import Foundation
import Markdown
import Mustache

public struct Tuzuru {
    private let sourceLoader: SourceLoader
    private let blogGenerator: BlogGenerator
    private let configuration: BlogConfiguration

    public init(
        fileManager: FileManager = .default,
        configuration: BlogConfiguration,
    ) throws {
        sourceLoader = SourceLoader(configuration: configuration)
        blogGenerator = try BlogGenerator(configuration: configuration, fileManager: fileManager)
        self.configuration = configuration
    }

    public func loadSources(_: BlogSourceLayout) async throws -> Source {
        try await sourceLoader.loadSources()
    }

    public func generate(_ source: Source) async throws -> FilePath {
        try blogGenerator.generate(source)
    }

    // MARK: - Static Configuration Methods
    
    public static func loadConfiguration(from path: String?) throws -> BlogConfiguration {
        let loader = BlogConfigurationLoader()
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
        let bundle = try TuzuruResources.resourceBundle()
        let initializer = BlogInitializer(fileManager: fileManager, bundle: bundle)
        
        let templatesDir = path.appending("templates")
        try initializer.copyTemplateFiles(to: templatesDir)

        let assetsDir = path.appending("assets")
        try initializer.copyAssetFiles(to: assetsDir)

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
        
        let importer = BlogImporter()
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
    
    // MARK: - Amend Methods
    
    public func amendFile(
        filePath: String,
        newDate: String? = nil,
        newAuthor: String? = nil,
        fileManager: FileManager = .default
    ) async throws {
        let amender = FileAmender(configuration: configuration, fileManager: fileManager, workingDirectory: FilePath(fileManager.currentDirectoryPath))
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
