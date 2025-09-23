import Foundation
import Subprocess

/// Thin wrapper around git command execution to reduce ceremonial code
struct GitWrapper {
    struct Error: Swift.Error {
        let message: String
        let exitStatus: Int
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
            case .exited(let code),
                 .unhandledException(let code):
                throw Error(message: result.standardError ?? "", exitStatus: Int(code))
            }
        } catch {
            let command = "git \(arguments.joined(separator: " "))"
            throw GitCommitterError.commandFailed(command, error.localizedDescription)
        }
    }
}
