import ArgumentParser
import Foundation
import TuzuruLib

struct ImportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import Hugo/Jekyll markdown files with YAML front matter to Tuzuru format"
    )

    @Argument(help: "Source directory containing markdown files to import")
    var sourcePath: String

    @Option(name: .shortAndLong, help: "Destination directory (default: contents/)")
    var destination: String = "contents/"

    @Flag(name: .shortAndLong, help: "Import as unlisted content")
    var unlisted: Bool = false

    @Flag(name: [.long, .customShort("n")], help: "Dry run - show what would be imported without making changes")
    var dryRun: Bool = false

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

        let destinationPath = unlisted ? blogConfig.sourceLayout.unlisted.string : destination

        let options = BlogImporter.ImportOptions(
            sourcePath: sourcePath,
            destinationPath: destinationPath
        )

        let importer = BlogImporter()
        let result = try await importer.importFiles(options: options, dryRun: dryRun)

        // Summary
        print("\n📊 Import Summary:")
        print("   ✅ Imported: \(result.importedCount) files")
        if result.skippedCount > 0 {
            print("   ⏭️  Skipped: \(result.skippedCount) files")
        }
        if result.errorCount > 0 {
            print("   ❌ Errors: \(result.errorCount) files")
        }

        if !dryRun && result.importedCount > 0 {
            print("📁 Files imported to: \(destinationPath)")
            print("🔗 Git commits created with original publication dates")
        }
    }
}
