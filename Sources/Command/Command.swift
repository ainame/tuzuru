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
