import ArgumentParser
import Foundation
import TuzuruLib
import System

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

        // Generate default configuration
        let defaultConfig = BlogConfiguration(
            sourceLayout: SourceLayout(
                templates: Templates(
                    layoutFile: FilePath("templates/layout.mustache"),
                    postFile: FilePath("templates/post.mustache"),
                    listFile: FilePath("templates/list.mustache"),
                ),
                contents: FilePath("contents"),
                unlisted: FilePath("contents/unlisted"),
                assets: FilePath("assets"),
            ),
            output: OutputOptions(
                directory: "blog",
                style: .subdirectory,
            ),
            metadata: BlogMetadata(
                blogName: "My Blog",
                copyright: "2025 My Blog",
                locale: Locale(identifier: "en_GB"),
            ),
        )

        // Write tuzuru.json
        print("⚙️ Generating tuzuru.json...")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let configData = try encoder.encode(defaultConfig)
        try configData.write(to: URL(fileURLWithPath: configPath.string))
        print("  ✅ Created tuzuru.json")

        // Copy template and asset files from bundle
        let initializer = BlogInitializer(fileManager: fileManager)
        
        print("📄 Copying template files...")
        let templatesDir = currentPath.appending("templates")

        do {
            try initializer.copyTemplateFiles(to: templatesDir)
            print("  ✅ Copied template files")
        } catch {
            print("  ⚠️ Warning: Failed to copy template files: \(error)")
        }

        print("🎨 Copying asset files...")
        let assetsDir = currentPath.appending("assets")

        do {
            try initializer.copyAssetFiles(to: assetsDir)
            print("  ✅ Copied main.css to assets/")
        } catch {
            print("  ⚠️ Warning: Failed to copy asset files: \(error)")
        }

        // Create directory structure
        print("📁 Creating directory structure...")
        let directories = [
            currentPath.appending("contents"),
            currentPath.appending("contents/unlisted"),
        ]

        for directory in directories {
            try fileManager.createDirectory(atPath: directory.string, withIntermediateDirectories: true)
            print("  ✅ Created \(directory.lastComponent?.string ?? "")/")
        }

        print("🎉 Site initialized successfully!")
        print("📋 Next steps:")
        print("  1. Add your markdown files to contents/")
        print("  2. Add unlisted pages (like /about) to contents/unlisted/")
        print("  3. Customize templates in templates/")
        print("  4. Run 'tuzuru generate' to build your site")
    }
}
