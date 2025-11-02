import ArgumentParser
import Foundation
import Logging
import TuzuruLib

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Generate a configuration file and templates to set up a project",
    )

    mutating func run() async throws {
        // Create logger
        let logger = Logger(label: "com.ainame.tuzuru")

        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)

        logger.info("Initializing new Tuzuru site")

        do {
            try await Tuzuru.initializeBlog(fileManager: fileManager, logger: logger)

            logger.info("Generated tuzuru.json")
            logger.info("  Created tuzuru.json")

            logger.info("Copied template files")
            logger.info("  Copied template files")

            logger.info("Copied asset files")
            logger.info("  Copied main.css to assets/")

            logger.info("Created directory structure")
            logger.info("  Created contents/")
            logger.info("  Created unlisted/")

            logger.info("Site initialized successfully!")
            logger.info("Next steps:")
            logger.info("  1. Add your markdown files to contents/")
            logger.info("  2. Add unlisted pages (like /about) to contents/unlisted/")
            logger.info("  3. Customize templates in templates/")
            logger.info("  4. Run 'tuzuru generate' to build your site")

        } catch let error as TuzuruError {
            logger.error("\(error.localizedDescription)")
            return
        } catch {
            logger.warning("Initialization completed with some issues: \(error)")
        }
    }
}
