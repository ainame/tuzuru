import Foundation
import System
import Markdown
import Mustache

public struct Tuzuru {
    private let contentLoader: ContentLoader
    private let siteGenerator: BlogGenerator

    public init(fileManager: FileManager = .default, configuration: BlogConfiguration = BlogConfiguration()) {
        self.contentLoader = ContentLoader(fileManager: fileManager)
        self.siteGenerator = BlogGenerator(fileManager: fileManager, configuration: configuration)
    }

    public func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        return try await contentLoader.loadSources(sourceLayout)
    }

    public func generate(_ source: Source) throws -> FilePath {
        return try siteGenerator.generate(source)
    }
}
