import Foundation

/// Handles amending file metadata by creating marker commits
struct FileAmender {
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper

    init(
        configuration: BlogConfiguration,
        fileManager: FileManagerWrapper,
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }
    
    func amendFile(
        filePath: FilePath,
        newDate: String? = nil,
        newAuthor: String? = nil
    ) async throws {
        // Verify file exists
        guard fileManager.fileExists(atPath: filePath) else {
            throw TuzuruError.fileNotFound(filePath.string)
        }

        // Parse and validate the date if provided
        var parsedDate: Date?
        if let dateString = newDate {
            parsedDate = DateUtils.parseDate(dateString)
            guard parsedDate != nil else {
                throw TuzuruError.invalidDateFormat(dateString)
            }
        }

        try await createMarkerCommit(
            filePath: filePath,
            newDate: parsedDate,
            newAuthor: newAuthor
        )
    }

    private func createMarkerCommit(
        filePath: FilePath,
        newDate: Date?,
        newAuthor: String?
    ) async throws {
        // Append an empty line to the file (minimal, invisible change)
        let fileHandle = try FileHandle(
            forWritingTo: URL(filePath: filePath.string, relativeTo: URL(string: fileManager.workingDirectory.string)),
        )
        defer { fileHandle.closeFile() }
        
        fileHandle.seekToEndOfFile()
        fileHandle.write("\n".data(using: .utf8)!)

        // Stage the file
        try await GitWrapper.run(
            arguments: ["add", filePath.string],
            workingDirectory: fileManager.workingDirectory,
        )

        // Build commit message
        var updates: [String] = []
        if newDate != nil {
            updates.append("publishedAt")
        }
        if newAuthor != nil {
            updates.append("author")
        }
        let updateString = updates.joined(separator: " and ")
        let commitMessage = "[tuzuru amend] Updated \(updateString) for \(filePath.string)"

        // Build git commit arguments
        var commitArgs = ["commit", "-m", commitMessage]
        
        // Add custom author if provided
        if let newAuthor = newAuthor {
            commitArgs.append("--author=\(newAuthor) <\(newAuthor.lowercased().replacingOccurrences(of: " ", with: ""))@tuzuru.amend>")
        }
        
        // Add custom date if provided
        if let newDate = newDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.timeZone = TimeZone.current
            let dateString = formatter.string(from: newDate)
            commitArgs.append("--date=\(dateString)")
        }

        // Create the commit
        try await GitWrapper.run(
            arguments: commitArgs,
            workingDirectory: fileManager.workingDirectory,
        )
    }
}
