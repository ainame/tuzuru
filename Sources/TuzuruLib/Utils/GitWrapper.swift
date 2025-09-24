import Foundation
import Subprocess

/// Thin wrapper around git command execution to reduce ceremonial code
struct GitWrapper {
    enum Error: Swift.Error {
        case failed(message: String, exitStatus: Int)
        case exception(message: String, signal: Int)
    }

    /// Executes a git command with the given arguments
    /// - Parameter arguments: Git command arguments (excluding "git")
    /// - Returns: Trimmed standard output from the git command
    /// - Throws: GitCommitterError if the command fails
    @discardableResult
    static func run(arguments: [String], workingDirectory: FilePath? = nil) async throws -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: Arguments(arguments),
                workingDirectory: workingDirectory,
                output: .string(limit: .max),
                error: .string(limit: .max)
            )

            switch result.terminationStatus {
            case .exited(let code) where code == 0:
                return result.standardOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            case .exited(let code):
                throw Error.failed(message: result.standardError ?? "", exitStatus: Int(code))
            case .unhandledException(let signal):
                throw Error.exception(message: result.standardError ?? "", signal: Int(signal))
            }
        } catch {
            let command = "git \(arguments.joined(separator: " "))"
            throw GitCommitterError.commandFailed(command, error.localizedDescription)
        }
    }
}
