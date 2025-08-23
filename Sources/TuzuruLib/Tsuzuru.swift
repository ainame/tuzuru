import Foundation
import System
import Markdown
import Mustache

public struct Tuzuru {
    private let contentLoader: ContentLoader
    private let siteGenerator: BlogGenerator
    private let blogConfiguration: BlogConfiguration

    public init(
        fileManager: FileManager = .default,
        configuration: BlogConfiguration
    ) throws {
        self.contentLoader = ContentLoader(configuration: configuration)
        self.siteGenerator = try BlogGenerator(fileManager: fileManager, configuration: configuration)
        self.blogConfiguration = configuration
    }

    public func run() async throws -> FilePath {
        let source: Source = try await loadSources(blogConfiguration.sourceLayout)
        let outputPath: FilePath = try await generate(source)
        return outputPath
    }

    public func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        try await contentLoader.loadSources(blogConfiguration.sourceLayout)
    }

    public func generate(_ source: Source) async throws -> FilePath {
        try siteGenerator.generate(source)
    }
}
