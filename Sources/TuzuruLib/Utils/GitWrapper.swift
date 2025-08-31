import Foundation
import Subprocess

/// Thin wrapper around git command execution to reduce ceremonial code
struct GitWrapper {

    /// Executes a git command with the given arguments
    /// - Parameter arguments: Git command arguments (excluding "git")
    /// - Returns: Trimmed standard output from the git command
    /// - Throws: GitCommitterError if the command fails
    @discardableResult
    static func run(arguments: [String]) async throws -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: Arguments(arguments),
                output: .string(limit: .max),
                error: .string(limit: .max)
            )
            return result.standardOutput?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            let command = "git \(arguments.joined(separator: " "))"
            throw GitCommitterError.commandFailed(command, error.localizedDescription)
        }
    }
}
