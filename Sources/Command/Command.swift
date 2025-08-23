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
        let siteConfig = BlogConfiguration()
        
        // Set up source layout using configuration
        let sourceLayout = SourceLayout(
            layoutFile: currentPath.appending(siteConfig.templates.layoutFile),
            contents: currentPath.appending("contents"), // Could be configurable too
            assets: currentPath.appending("assets")       // Could be configurable too
        )
        
        // Initialize Tuzuru with configuration
        let tuzuru = Tuzuru(configuration: siteConfig)
        
        print("🔍 Scanning for markdown files in contents/...")
        
        // Load sources (scan markdown files and get git info)
        let source = try await tuzuru.loadSources(sourceLayout)
        
        print("📝 Found \(source.pages.count) articles")
        for article in source.pages {
            print("  - \(article.title) by \(article.author)")
        }
        
        print("🚀 Generating site...")
        
        // Generate the site - now returns simple FilePath
        let outputDirectory = try tuzuru.generate(source)
        
        print("✅ Site generated successfully in \(outputDirectory.string)/")
        print("📄 Generated:")
        print("  - \(siteConfig.output.indexFileName) (list page)")
        for article in source.pages {
            let articleName = siteConfig.output.generateFileName(for: article.path)
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
