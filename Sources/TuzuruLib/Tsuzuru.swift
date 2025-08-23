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
    ) {
        self.contentLoader = ContentLoader()
        self.siteGenerator = BlogGenerator(fileManager: fileManager, configuration: configuration)
        self.blogConfiguration = configuration
    }

    public func run() async throws -> FilePath {
        let source: Source = try await loadSources(blogConfiguration.sourceLayout)
        let outputPath: FilePath = try generate(source)
        return outputPath
    }

    func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        return try await contentLoader.loadSources(sourceLayout)
    }

    func generate(_ source: Source) throws -> FilePath {
        return try siteGenerator.generate(source)
    }
}
