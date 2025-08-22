import Foundation
import SystemPackage
import Subprocess

public struct GitWrapper {
    public init() {}
    
    public func logs(for filePath: FilePath) -> [GitLog] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = [
            "log",
            "--pretty=format:%H%n%s%n%an%n%ae%n%ci",
            "--",
            filePath.string
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
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
                    date: date
                )
                logs.append(log)
            }
            
            i += 5
        }
        
        return logs
    }
    
    private func parseGitDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: dateString)
    }
}

public struct GitLog {
    public let commitHash: String
    public let commitMessage: String
    public let author: String
    public let email: String
    public let date: Date
}
