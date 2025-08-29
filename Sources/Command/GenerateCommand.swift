import ArgumentParser
import Foundation
import TuzuruLib
import System

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
    )

    mutating func run() async throws {
        let currentPath = FilePath(FileManager.default.currentDirectoryPath)
        let configPath = currentPath.appending("tuzuru.json")

        // Load configuration from tuzuru.json
        guard FileManager.default.fileExists(atPath: configPath.string) else {
            print("❌ tuzuru.json not found. Run 'tuzuru init' first to initialize a new site.")
            return
        }

        let configData = try Data(contentsOf: URL(fileURLWithPath: configPath.string))
        let decoder = JSONDecoder()
        let blogConfig = try decoder.decode(BlogConfiguration.self, from: configData)

        // Initialize Tuzuru with configuration
        let tuzuru = try Tuzuru(configuration: blogConfig)

        print("🔍 Scanning for markdown files in \(blogConfig.sourceLayout.contents.string)/...")

        // Load sources (scan markdown files and get git info)
        let source = try await tuzuru.loadSources(blogConfig.sourceLayout)

        print("📝 Found \(source.posts.count) posts")
        for post in source.posts {
            print("  - \(post.title) by \(post.author)")
        }

        print("🚀 Generating site...")

        // Generate the site - now returns simple FilePath
        let outputDirectory = try await tuzuru.generate(source)

        print("✅ Site generated successfully in \(outputDirectory.string)/")
        print("📄 Generated:")
        print("  - \(blogConfig.outputOptions.indexFileName) (list page)")
        let pathGenerator = PathGenerator(configuration: blogConfig.outputOptions, contentsBasePath: blogConfig.sourceLayout.contents, unlistedBasePath: blogConfig.sourceLayout.unlisted)
        for post in source.posts {
            let postName = pathGenerator.generateOutputPath(for: post.path, isUnlisted: post.isUnlisted)
            print("  - \(postName)")
        }
    }
}
