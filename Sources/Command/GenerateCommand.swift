import ArgumentParser
import Foundation
import Logging
import TuzuruLib

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate blog from markdown files in contents and assets",
    )

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        // Create logger
        let logger = Logger(label: "com.ainame.tuzuru")

        // Load configuration
        let blogConfig = try Tuzuru.loadConfiguration(from: config)

        // Initialize Tuzuru with configuration
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: blogConfig, logger: logger)

        logger.info("Scanning for markdown files", metadata: [
            "directory": .string(blogConfig.sourceLayout.contents.string)
        ])

        // Phase 1: Load sources (scan markdown files and get git info)
        let rawSource = try await tuzuru.loadSources(blogConfig.sourceLayout)

        logger.info("Found posts", metadata: ["count": .stringConvertible(rawSource.posts.count)])

        logger.info("Processing markdown content")

        // Phase 2: Process contents (convert markdown to HTML)
        let processedSource = try await tuzuru.processContents(rawSource)

        for post in processedSource.posts {
            logger.info("  - \(post.title) by \(post.author)")
        }

        logger.info("Generating site")

        // Phase 3: Generate the site
        let outputDirectory = try await tuzuru.generate(processedSource)

        logger.info("Site generated successfully", metadata: [
            "outputDirectory": .string(outputDirectory.string)
        ])
        logger.info("Generated:")
        logger.info("  - \(blogConfig.output.indexFileName) (list page)")
        let displayPaths = tuzuru.generateDisplayPaths(for: processedSource)
        for postName in displayPaths {
            logger.info("  - \(postName)")
        }
    }
}
