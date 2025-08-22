import ArgumentParser
import Foundation
import SystemPackage
import TuzuruLib

@main
struct MainCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tuzuru",
        subcommands: [
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
        commandName: "add"
    )

    @Argument
    var title: String

    mutating func run() async throws {
    }
}

struct PreviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview"
    )

    @Option(name: .shortAndLong)
    var port: Int = 8080

    mutating func run() async throws {
        print(port)
    }
}

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate"
    )

    mutating func run() async throws {
        let gitWrapper = GitWrapper()
        let currentPath = FilePath(FileManager.default.currentDirectoryPath)
        let logs = gitWrapper.logs(for: currentPath)
        
        for log in logs {
            print("\(log.commitHash) - \(log.commitMessage) by \(log.author)")
        }
    }
}

struct WatchCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch"
    )

    mutating func run() async throws {
    }
}
