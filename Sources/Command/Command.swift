import ArgumentParser
import Foundation
import Logging
import TuzuruLib

// Bootstrap logging once before main entry point
private let bootstrapLogging: Void = {
    LoggingSystem.bootstrap { _ in
        SimpleLogHandler()
    }
}()

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        abstract: "Simple static blog generator",
        version: "0.6.1", // x-release-please-version
        subcommands: [
            InitCommand.self,
            GenerateCommand.self,
            ImportCommand.self,
            AmendCommand.self,
            ListCommand.self,
            PreviewCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )

    init() {
        // Ensure bootstrap happens before anything else
        _ = bootstrapLogging
    }
}
