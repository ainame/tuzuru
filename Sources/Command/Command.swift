import ArgumentParser
import Foundation
import TuzuruLib

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        abstract: "Simple static blog generator",
        version: "0.4.0", // x-release-please-version
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
}
