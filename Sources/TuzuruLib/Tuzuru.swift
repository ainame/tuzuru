import Foundation
import Markdown
import Mustache

public struct Tuzuru {
    private let sourceLoader: SourceLoader
    private let siteGenerator: BlogGenerator
    private let configuration: BlogConfiguration

    public init(
        fileManager: FileManager = .default,
        configuration: BlogConfiguration,
    ) throws {
        sourceLoader = SourceLoader(configuration: configuration)
        siteGenerator = try BlogGenerator(fileManager: fileManager, configuration: configuration)
        self.configuration = configuration
    }

    public func run() async throws -> FilePath {
        let source: Source = try await loadSources(configuration.sourceLayout)
        let outputPath: FilePath = try await generate(source)
        return outputPath
    }

    public func loadSources(_: SourceLayout) async throws -> Source {
        try await sourceLoader.loadSources()
    }

    public func generate(_ source: Source) async throws -> FilePath {
        try siteGenerator.generate(source)
    }
}
