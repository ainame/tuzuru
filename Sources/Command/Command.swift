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

struct AddCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add"
    )

    @Argument
    var title: String

    mutating func run() async throws {
    }
}

struct PreviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview"
    )

    @Option(name: .shortAndLong)
    var port: Int = 8080

    mutating func run() async throws {
        print(port)
    }
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
                templates: currentPath.appending("templates"),
                contents: currentPath.appending("contents"),
                assets: currentPath.appending("assets"),
            ),
            templates: Templates(
                layoutFile: "layout.html.mustache",
                articleFile: "article.html.mustache",
                listFile: "list.html.mustache",
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
        let tuzuru = Tuzuru(configuration: blogConfig)
        
        print("🔍 Scanning for markdown files in contents/...")
        
        // Load sources (scan markdown files and get git info)
        let source = try await tuzuru.loadSources(blogConfig.sourceLayout)
        
        print("📝 Found \(source.pages.count) articles")
        for article in source.pages {
            print("  - \(article.title) by \(article.author)")
        }
        
        print("🚀 Generating site...")
        
        // Generate the site - now returns simple FilePath
        let outputDirectory = try tuzuru.generate(source)
        
        print("✅ Site generated successfully in \(outputDirectory.string)/")
        print("📄 Generated:")
        print("  - \(blogConfig.outputOptions.indexFileName) (list page)")
        let pathGenerator = PathGenerator(configuration: blogConfig.outputOptions)
        for article in source.pages {
            let articleName = pathGenerator.generateOutputPath(for: article.path)
            print("  - \(articleName)")
        }
    }
}

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch"
    )

    mutating func run() async throws {
    }
}
