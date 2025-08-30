import ArgumentParser
import Foundation
import TuzuruLib

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        subcommands: [
            InitCommand.self,
            GenerateCommand.self,
            ImportCommand.self,
        ],
        defaultSubcommand: GenerateCommand.self,
    )
}
