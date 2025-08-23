import ArgumentParser
import Foundation
import TuzuruLib

import System

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        subcommands: [
            InitCommand.self,
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

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
    )

    mutating func run() async throws {
        let currentPath = FilePath(FileManager.default.currentDirectoryPath)
        let fileManager = FileManager.default

        print("🚀 Initializing new Tuzuru site...")

        // Check if tuzuru.json already exists
        let configPath = currentPath.appending("tuzuru.json")
        if fileManager.fileExists(atPath: configPath.string) {
            print("❌ tuzuru.json already exists. Aborting initialization.")
            return
        }

        // Create directory structure
        print("📁 Creating directory structure...")
        let directories = [
            currentPath.appending("assets"),
            currentPath.appending("contents"),
            currentPath.appending("templates"),
        ]

        for directory in directories {
            try fileManager.createDirectory(atPath: directory.string, withIntermediateDirectories: true)
            print("  ✅ Created \(directory.lastComponent?.string ?? "")/")
        }

        // Generate default configuration
        let defaultConfig = BlogConfiguration(
            sourceLayout: SourceLayout(
                templates: Templates(
                    layoutFile: FilePath("templates/layout.html.mustache"),
                    articleFile: FilePath("templates/article.html.mustache"),
                    listFile: FilePath("templates/list.html.mustache"),
                ),
                contents: FilePath("contents"),
                assets: FilePath("assets"),
            ),
            output: OutputOptions(
                directory: "blog",
                style: .subdirectory,
            ),
            metadata: BlogMetadata(
                blogName: "My Blog",
                copyright: "2025 My Blog",
            ),
        )

        // Write tuzuru.json
        print("⚙️ Generating tuzuru.json...")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let configData = try encoder.encode(defaultConfig)
        try configData.write(to: URL(fileURLWithPath: configPath.string))
        print("  ✅ Created tuzuru.json")

        // Copy template files from bundle
        print("📄 Copying template files...")
        let templatesDir = currentPath.appending("templates")

        do {
            try SiteInitializer.copyTemplateFiles(to: templatesDir)
            print("  ✅ Copied template files")
        } catch {
            print("  ⚠️ Warning: Failed to copy template files: \(error)")
        }

        print("🎉 Site initialized successfully!")
        print("📋 Next steps:")
        print("  1. Add your markdown files to contents/")
        print("  2. Customize templates in templates/")
        print("  3. Run 'tuzuru generate' to build your site")
    }
}

struct AddCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
    )

    @Argument
    var title: String

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}

struct PreviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview",
    )

    @Option(name: .shortAndLong)
    var port: Int = 8080

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch",
    )

    mutating func run() async throws {
        fatalError("To be implemented")
    }
}
