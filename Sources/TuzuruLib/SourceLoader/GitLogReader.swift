import Foundation

struct GitLogReader: Sendable {
    let workingDirectory: FilePath

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()

    func baseCommit(for filePath: FilePath) async -> GitLog? {
        do {
            let output = try await GitWrapper.run(
                arguments: [
                    "log",
                    "--follow",
                    "--pretty=format:%H%n%s%n%an%n%ae%n%ai",
                    "--",
                    filePath.string,
                ],
                workingDirectory: workingDirectory
            )
            let allLogs = parseGitLogs(from: output)
            return findBaseCommit(from: allLogs)
        } catch {
            return nil
        }
    }

    private func parseGitLogs(from output: String) -> [GitLog] {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var logs: [GitLog] = []

        var lineIndex = 0
        while lineIndex + 4 < lines.count {
            let commitHash = lines[lineIndex]
            let commitMessage = lines[lineIndex + 1]
            let author = lines[lineIndex + 2]
            let email = lines[lineIndex + 3]
            let dateString = lines[lineIndex + 4]

            if let date = parseGitDate(dateString) {
                let log = GitLog(
                    commitHash: commitHash,
                    commitMessage: commitMessage,
                    author: author,
                    email: email,
                    date: date,
                )
                logs.append(log)
            }

            lineIndex += 5
        }

        return logs
    }

    private func parseGitDate(_ dateString: String) -> Date? {
        formatter.date(from: dateString)
    }

    /// Finds the appropriate base commit for metadata extraction
    /// If a marker commit exists, use it; otherwise use the original first commit
    private func findBaseCommit(from logs: [GitLog]) -> GitLog? {
        // Find the first marker commit (most recent amend operation)
        if let markerCommit = logs.first(where: { $0.commitMessage.hasPrefix("[tuzuru amend]") }) {
            return markerCommit
        }

        // No marker commits found, use the original first commit (last in chronological order)
        return logs.last
    }
}
