import ArgumentParser
import Foundation
import TuzuruLib

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
    )

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        // Load configuration
        let loader = BlogConfigurationLoader()
        let blogConfig: BlogConfiguration
        
        do {
            blogConfig = try loader.load(from: config)
        } catch let error as BlogConfigurationLoader.LoadError {
            print("❌ \(error.localizedDescription)")
            return
        }

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
        print("  - \(blogConfig.output.indexFileName) (list page)")
        let pathGenerator = PathGenerator(configuration: blogConfig.output, contentsBasePath: blogConfig.sourceLayout.contents, unlistedBasePath: blogConfig.sourceLayout.unlisted)
        for post in source.posts {
            let postName = pathGenerator.generateOutputPath(for: post.path, isUnlisted: post.isUnlisted)
            print("  - \(postName)")
        }
    }
}
