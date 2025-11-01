import ArgumentParser
import Foundation
import Logging
import TuzuruLib

struct ImportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "import",
        abstract: "Import Hugo/Jekyll markdown files with YAML front matter to Tuzuru format"
    )

    @Argument(help: "Source directory containing markdown files to import")
    var sourcePath: String

    @Option(name: .shortAndLong, help: "Destination directory (default: contents/imported/ or sourceLayout.imported in tuzuru.json)")
    var destination: String = "contents/imported/"

    @Flag(name: .shortAndLong, help: "Import as unlisted content")
    var unlisted: Bool = false

    @Flag(name: [.long, .customShort("n")], help: "Dry run - show what would be imported without making changes")
    var dryRun: Bool = false

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        // Create logger
        let logger = Logger(label: "com.ainame.tuzuru")

        // Load configuration
        let blogConfig = try Tuzuru.loadConfiguration(from: config)

        let destinationPath = unlisted ? blogConfig.sourceLayout.unlisted.string : destination

        // Initialize Tuzuru with configuration
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: blogConfig, logger: logger)
        let result = try await tuzuru.importFiles(from: sourcePath, to: destinationPath, dryRun: dryRun)

        // Summary
        logger.info("")
        logger.info("Import Summary:")
        logger.info("   Imported: \(result.importedCount) files")
        if result.skippedCount > 0 {
            logger.info("   Skipped: \(result.skippedCount) files")
        }
        if result.errorCount > 0 {
            logger.info("   Errors: \(result.errorCount) files")
        }

        if !dryRun && result.importedCount > 0 {
            logger.info("Files imported to: \(destinationPath)")
            logger.info("Git commits created with original publication dates")
        }
    }
}
