import Foundation
import ArgumentParser
import TuzuruLib
import ToyHttpServer

struct ServeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Start a local HTTP server to serve the generated blog"
    )

    @Option(name: [.long, .customShort("p")], help: "Port to serve on (default: 8000)")
    var port: Int = 8000
    
    @Option(name: [.long, .customShort("d")], help: "Directory to serve (default: blog)")
    var directory: String = "blog"
    
    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let servePath = fileManager.workingDirectory.appending(directory)
        
        // Check if directory exists
        guard fileManager.fileExists(atPath: servePath) else {
            print("❌ Directory '\(directory)' does not exist")
            print("💡 Run 'tuzuru generate' first to create the blog directory")
            throw ExitCode.failure
        }
        
        let server = ToyHttpServer(port: port, servePath: servePath.string)
        try await server.start()
    }
}
