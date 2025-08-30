import Foundation
import Subprocess

/// Handles git operations for creating commits with custom dates
struct GitCommitter: Sendable {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    /// Creates a git commit for a file with a custom date
    /// - Parameters:
    ///   - filePath: Path to the file to commit
    ///   - message: Commit message
    ///   - date: Date to use for the commit
    ///   - author: Author name and email in format "Name <email>"
    /// - Throws: GitCommitterError if the operation fails
    func commit(filePath: FilePath, message: String, date: Date, author: String? = nil) async throws {
        let gitDateString = dateFormatter.string(from: date)
        
        // Add the file to staging area
        _ = try await addFileToGit(filePath)
        
        // Create the commit with custom date
        if let author = author {
            _ = try await commitWithAuthor(message: message, date: gitDateString, author: author)
        } else {
            _ = try await commitWithoutAuthor(message: message, date: gitDateString)
        }
    }
    
    private func addFileToGit(_ filePath: FilePath) async throws -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: [
                    "add",
                    filePath.string,
                ],
                output: .string(limit: .max),
                error: .string(limit: .max)
            )
            return result.standardOutput ?? ""
        } catch {
            throw GitCommitterError.commandFailed("git add \(filePath.string)", error.localizedDescription)
        }
    }
    
    private func commitWithAuthor(message: String, date: String, author: String) async throws -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: [
                    "commit",
                    "-m", message,
                    "--author-date", date,
                    "--author", author,
                ],
                output: .string(limit: .max),
                error: .string(limit: .max)
            )
            return result.standardOutput ?? ""
        } catch {
            throw GitCommitterError.commandFailed("git commit", error.localizedDescription)
        }
    }
    
    private func commitWithoutAuthor(message: String, date: String) async throws -> String {
        do {
            let result = try await Subprocess.run(
                .name("git"),
                arguments: [
                    "commit",
                    "-m", message,
                    "--author-date", date,
                ],
                output: .string(limit: .max),
                error: .string(limit: .max)
            )
            return result.standardOutput ?? ""
        } catch {
            throw GitCommitterError.commandFailed("git commit", error.localizedDescription)
        }
    }
    
    /// Creates multiple commits for a batch of files
    /// - Parameters:
    ///   - files: Array of file information to commit
    /// - Throws: GitCommitterError if any operation fails
    func commitBatch(_ files: [(filePath: FilePath, message: String, date: Date, author: String?)]) async throws {
        for fileInfo in files {
            try await commit(
                filePath: fileInfo.filePath,
                message: fileInfo.message,
                date: fileInfo.date,
                author: fileInfo.author
            )
        }
    }
    
    
    /// Generates a commit message for an imported post
    /// - Parameters:
    ///   - title: Post title
    ///   - originalDate: Original publication date
    /// - Returns: Generated commit message
    func generateImportCommitMessage(title: String, originalDate: Date) -> String {
        let dateString = ISO8601DateFormatter.shortDate.string(from: originalDate)
        return "[tuzuru import]: \(title) (originally published \(dateString))"
    }
}

enum GitCommitterError: Error, LocalizedError, Sendable {
    case commandFailed(String, String)
    case subprocessError(Error)
    case invalidAuthorFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let error):
            return "Git command failed: '\(command)' - \(error)"
        case .subprocessError(let error):
            return "Subprocess error: \(error.localizedDescription)"
        case .invalidAuthorFormat(let author):
            return "Invalid author format: '\(author)'. Expected format: 'Name <email>'"
        }
    }
}

// MARK: - DateFormatter Extensions

extension ISO8601DateFormatter {
    public static let shortDate: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()
}
