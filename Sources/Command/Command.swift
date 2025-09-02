import ArgumentParser
import Foundation
import TuzuruLib

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        abstract: "Simple static blog generator",
        version: "0.0.9",
        subcommands: [
            InitCommand.self,
            GenerateCommand.self,
            ImportCommand.self,
            AmendCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )
}
