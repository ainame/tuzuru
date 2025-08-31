import Foundation

struct GitLogReader: Sendable {
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()

    func logs(for filePath: FilePath) async -> [GitLog] {
        do {
            let output = try await GitWrapper.run(arguments: [
                "log",
                "--pretty=format:%H%n%s%n%an%n%ae%n%ai",
                "--",
                filePath.string
            ])
            return parseGitLogs(from: output)
        } catch {
            return []
        }
    }

    private func parseGitLogs(from output: String) -> [GitLog] {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var logs: [GitLog] = []

        var i = 0
        while i + 4 < lines.count {
            let commitHash = lines[i]
            let commitMessage = lines[i + 1]
            let author = lines[i + 2]
            let email = lines[i + 3]
            let dateString = lines[i + 4]

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

            i += 5
        }

        return logs
    }

    private func parseGitDate(_ dateString: String) -> Date? {
        formatter.date(from: dateString)
    }
}
