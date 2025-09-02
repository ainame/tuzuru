import ArgumentParser
import Foundation
import TuzuruLib

struct AmendCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "amend",
        abstract: "Update publishedAt date and/or author for a markdown file by creating a marker commit"
    )

    @Argument(help: "Path to the markdown file (relative to contents directory)")
    var filePath: String

    @Option(name: [.long, .customShort("d")], help: "New published date (supports various formats like '2023-12-01', '2023-12-01 10:30:00 +0900', etc.)")
    var publishedAt: String?

    @Option(name: [.long, .customShort("a")], help: "New author name")
    var author: String?

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        guard publishedAt != nil || author != nil else {
            throw ValidationError("At least one of --published-at or --author must be provided")
        }

        let blogConfig = try Tuzuru.loadConfiguration(from: config)
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: blogConfig)

        try await tuzuru.amendFile(
            filePath: filePath,
            newDate: publishedAt,
            newAuthor: author
        )
    }
}
