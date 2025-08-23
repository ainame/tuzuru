import ArgumentParser
import Foundation
import TuzuruLib

#if canImport(System)
import System
#else
import SystemPackage
#endif

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
        
        // Set up source layout
        let sourceLayout = SourceLayout(
            layoutFile: currentPath.appending("layout.mustache"),
            contents: currentPath.appending("contents"),
            assets: currentPath.appending("assets")
        )
        
        // Initialize Tuzuru
        let tuzuru = Tuzuru()
        
        print("🔍 Scanning for markdown files in contents/...")
        
        // Load sources (scan markdown files and get git info)
        let source = try await tuzuru.loadSources(sourceLayout)
        
        print("📝 Found \(source.pages.count) articles")
        for page in source.pages {
            print("  - \(page.title) by \(page.author)")
        }
        
        print("🚀 Generating site...")
        
        // Generate the site
        let siteLayout = try tuzuru.generate(source)
        
        print("✅ Site generated successfully in \(siteLayout.root.string)/")
        print("📄 Generated:")
        print("  - index.html (list page)")
        for page in source.pages {
            let articleName = "\(page.path.lastComponent?.stem ?? "untitled").html"
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
