import Foundation

/// Handles git operations for creating commits with custom dates
struct GitCommitter {
    private let iso8601DateFormatter = ISO8601DateFormatter()
    private let workingDirectory: FilePath

    init(workingDirectory: FilePath) {
        self.workingDirectory = workingDirectory
    }

    /// Creates a git commit for a file with a custom date
    /// - Parameters:
    ///   - filePath: Path to the file to commit
    ///   - message: Commit message
    ///   - date: Date to use for the commit
    ///   - author: Author name and email in format "Name <email>"
    /// - Throws: GitCommitterError if the operation fails
    func commit(filePath: FilePath, message: String, date: Date, author: String? = nil) async throws {
        let gitDateString = iso8601DateFormatter.string(from: date)

        // Add the file to staging area
        try await addFileToGit(filePath)

        // Create the commit with custom date
        if let author = author {
            try await commitWithAuthor(message: message, date: gitDateString, author: author)
        } else {
            try await commitWithoutAuthor(message: message, date: gitDateString)
        }
    }

    private func addFileToGit(_ filePath: FilePath) async throws {
        try await GitWrapper.run(
            arguments: [
                "add",
                filePath.string
            ],
            workingDirectory: workingDirectory
        )
    }

    private func commitWithAuthor(message: String, date: String, author: String) async throws {
        try await GitWrapper.run(
            arguments: [
                "commit",
                "-m", message,
                "--date", date,
                "--author", author
            ],
            workingDirectory: workingDirectory,
        )
    }

    private func commitWithoutAuthor(message: String, date: String) async throws {
        try await GitWrapper.run(
            arguments: [
                "commit",
                "-m", message,
                "--date", date
            ],
            workingDirectory: workingDirectory,
        )
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

    /// Gets the current author information for the most recent commit that modified the specified file
    /// - Parameter filePath: Path to the file to check
    /// - Returns: Author string in "Name <email>" format
    /// - Throws: GitCommitterError if the operation fails
    private func getCurrentAuthor(filePath: FilePath) async throws -> String {
        let output = try await GitWrapper.run(
            arguments: [
                "log",
                "-1",
                "--format=%an <%ae>",
                "--",
                filePath.string
            ],
            workingDirectory: workingDirectory,
        )

        guard !output.isEmpty else {
            throw GitCommitterError.commandFailed("git log", "No commit found for file")
        }

        return output
    }

    /// Generates a commit message for an imported post
    /// - Parameters:
    ///   - title: Post title
    ///   - originalDate: Original publication date
    /// - Returns: Generated commit message
    func generateImportCommitMessage(title: String, originalDate: Date) -> String {
        let dateString = iso8601DateFormatter.string(from: originalDate)
        return "[tuzuru import]: \(title) (originally published \(dateString))"
    }
}

enum GitCommitterError: Error, LocalizedError, Sendable {
    case commandFailed(String, String)
    case subprocessError(Error)
    case invalidAuthorFormat(String)
    case notAGitRepository

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let error):
            return "Git command failed: '\(command)' - \(error)"
        case .subprocessError(let error):
            return "Subprocess error: \(error.localizedDescription)"
        case .invalidAuthorFormat(let author):
            return "Invalid author format: '\(author)'. Expected format: 'Name <email>'"
        case .notAGitRepository:
            return "Not a git repository. Run 'git init' first to initialize a git repository."
        }
    }
}
