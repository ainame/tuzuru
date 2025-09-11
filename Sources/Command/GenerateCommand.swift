import ArgumentParser
import Foundation
import TuzuruLib

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate blog from markdown files in contents and assets",
    )

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        // Load configuration
        let blogConfig = try Tuzuru.loadConfiguration(from: config)

        // Initialize Tuzuru with configuration
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: blogConfig)

        print("🔍 Scanning for markdown files in \(blogConfig.sourceLayout.contents.string)/...")

        // Phase 1: Load sources (scan markdown files and get git info)
        let rawSource = try await tuzuru.loadSources(blogConfig.sourceLayout)

        print("📝 Found \(rawSource.posts.count) posts")

        print("🔄 Processing markdown content...")

        // Phase 2: Process contents (convert markdown to HTML)
        let processedSource = try await tuzuru.processContents(rawSource)

        for post in processedSource.posts {
            print("  - \(post.title) by \(post.author)")
        }

        print("🚀 Generating site...")

        // Phase 3: Generate the site
        let outputDirectory = try await tuzuru.generate(processedSource)

        print("✅ Site generated successfully in \(outputDirectory.string)/")
        print("📄 Generated:")
        print("  - \(blogConfig.output.indexFileName) (list page)")
        let displayPaths = tuzuru.generateDisplayPaths(for: processedSource)
        for postName in displayPaths {
            print("  - \(postName)")
        }
    }
}
