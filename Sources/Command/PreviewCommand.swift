import Foundation
import ArgumentParser
import TuzuruLib
import ToyHttpServer

@MainActor
private class RegenerationState {
    var currentSource: Source
    var pathMapping: [String: FilePath]
    var lastRequestTime: Date = Date()

    init(source: Source, pathMapping: [String: FilePath]) {
        self.currentSource = source
        self.pathMapping = pathMapping
    }
}

struct PreviewCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview",
        abstract: "Start a local HTTP server to preview the generated blog"
    )

    @Option(name: [.long, .customShort("p")], help: "Port to serve on (default: 8000)")
    var port: Int = 8000


    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)

        // Load configuration first to get the output directory
        let configuration = try Tuzuru.loadConfiguration(from: config)
        let outputDirectory = configuration.output.directory
        let servePath = fileManager.workingDirectory.appending(outputDirectory)

        // Check if directory exists
        guard fileManager.fileExists(atPath: servePath) else {
            print("❌ Directory '\(outputDirectory)' does not exist")
            print("💡 Run 'tuzuru generate' first to create the blog directory")
            throw ExitCode.failure
        }
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: configuration)

        // Generate initial blog to get source and path mapping
        let rawSource = try await tuzuru.loadSources(configuration.sourceLayout)
        let currentSource = try await tuzuru.processContents(rawSource)
        _ = try await tuzuru.generate(currentSource)

        let pathMapping = tuzuru.createPathMapping(for: currentSource)
        let state = await RegenerationState(source: currentSource, pathMapping: pathMapping)

        print("📋 Auto-regeneration enabled - files will be regenerated on request if modified")

        // Create hooks for auto-regeneration
        let beforeResponseHook: RequestHook = { context in
            let shouldRegenerate = await MainActor.run {
                tuzuru.shouldRegenerate(
                    requestPath: context.path,
                    lastRequestTime: state.lastRequestTime,
                    pathMapping: state.pathMapping
                )
            }

            if shouldRegenerate {
                print("🔄 Regenerating blog due to file changes for: \(context.path)")
                do {
                    let newSource = try await tuzuru.regenerate()
                    let newPathMapping = tuzuru.createPathMapping(for: newSource)
                    await MainActor.run {
                        state.currentSource = newSource
                        state.pathMapping = newPathMapping
                    }
                    print("✅ Blog regenerated successfully")
                } catch {
                    print("❌ Error regenerating blog: \(error)")
                    throw error
                }
            }

            await MainActor.run {
                state.lastRequestTime = context.timestamp
            }
        }

        let afterResponseHook: ResponseHook = { context, statusCode in
            // Optional: Could add logging or other post-response actions here
        }

        let server = ToyHttpServer(
            port: port,
            servePath: servePath.string,
            beforeResponseHook: beforeResponseHook,
            afterResponseHook: afterResponseHook
        )
        try await server.start()
    }
}
