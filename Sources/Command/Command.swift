import ArgumentParser
import Foundation
import TuzuruLib

import System

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        subcommands: [
            AddCommand.self,
            PreviewCommand.self,
            GenerateCommand.self,
            WatchCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )
}

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate"
    )

    mutating func run() async throws {
        let currentPath = FilePath(FileManager.default.currentDirectoryPath)

        // Create configuration with default values
        let blogConfig = BlogConfiguration(
            sourceLayout: SourceLayout(
                templates: Templates(
                    layoutFile: currentPath.appending("templates").appending("layout.html.mustache"),
                    articleFile: currentPath.appending("templates").appending("article.html.mustache"),
                    listFile: currentPath.appending("templates").appending("list.html.mustache"),
                ),
                contents: currentPath.appending("contents"),
                assets: currentPath.appending("assets"),
            ),
            output: OutputOptions(
                directory: "blog",
                indexFileName: "index.html",
                style: .subdirectory
            ),
            metadata: BlogMetadata(
                blogTitle: "My Blog",
                copyright: "2025 My Blog",
            )
        )

        // Initialize Tuzuru with configuration
        let tuzuru = try Tuzuru(configuration: blogConfig)

        print("🔍 Scanning for markdown files in contents/...")

        // Load sources (scan markdown files and get git info)
        let source = try await tuzuru.loadSources(blogConfig.sourceLayout)

        print("📝 Found \(source.articles.count) articles")
        for article in source.articles {
            print("  - \(article.title) by \(article.author)")
        }

        print("🚀 Generating site...")

        // Generate the site - now returns simple FilePath
        let outputDirectory = try await tuzuru.generate(source)

        print("✅ Site generated successfully in \(outputDirectory.string)/")
        print("📄 Generated:")
        print("  - \(blogConfig.outputOptions.indexFileName) (list page)")
        let pathGenerator = PathGenerator(configuration: blogConfig.outputOptions)
        for article in source.articles {
            let articleName = pathGenerator.generateOutputPath(for: article.path)
            print("  - \(articleName)")
        }
    }
}

struct AddCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add"
    )

    @Argument
    var title: String

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}

struct PreviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview"
    )

    @Option(name: .shortAndLong)
    var port: Int = 8080

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch"
    )

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}
