import Foundation
import System
import Markdown
import Mustache

public struct Tuzuru {
    private let contentLoader: ContentLoader
    private let siteGenerator: SiteGenerator

    public init(fileManager: FileManager = .default, configuration: SiteConfiguration = SiteConfiguration()) {
        self.contentLoader = ContentLoader(fileManager: fileManager)
        self.siteGenerator = SiteGenerator(fileManager: fileManager, configuration: configuration)
    }

    public func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        return try await contentLoader.loadSources(sourceLayout)
    }

    public func generate(_ source: Source) throws -> SiteLayout {
        return try siteGenerator.generate(source)
    }
}