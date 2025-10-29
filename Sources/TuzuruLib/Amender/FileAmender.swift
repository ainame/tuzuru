import Foundation

/// Handles amending file metadata by creating marker commits
struct FileAmender {
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper
    private let gitLogReader: GitLogReader

    init(
        configuration: BlogConfiguration,
        fileManager: FileManagerWrapper,
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
        self.gitLogReader = GitLogReader(workingDirectory: fileManager.workingDirectory)
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
        // Get previous marker commit to inherit unchanged metadata
        let previousCommit = await gitLogReader.baseCommit(for: filePath)

        // Determine final author and date, inheriting from previous marker commit when unchanged
        let finalAuthor: String?
        let finalDate: Date?

        if let previousCommit = previousCommit, previousCommit.commitMessage.hasPrefix("[tuzuru amend]") {
            // Previous marker commit exists, inherit unchanged values
            finalAuthor = newAuthor ?? previousCommit.author
            finalDate = newDate ?? previousCommit.date
        } else {
            // No previous marker commit, use provided values only
            finalAuthor = newAuthor
            finalDate = newDate
        }

        // Append an empty line to the file (minimal, invisible change)
        let fullFilePath = fileManager.workingDirectory.appending(filePath.string)
        do {
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: fullFilePath.string))
            defer { try? fileHandle.close() }
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: "\n".data(using: .utf8)!)
        }

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

        // Add author if we have one (either new or inherited)
        if let finalAuthor = finalAuthor {
            commitArgs.append("--author=\(finalAuthor) <\(finalAuthor.lowercased().replacingOccurrences(of: " ", with: ""))@tuzuru.amend>")
        }

        // Add date if we have one (either new or inherited)
        if let finalDate = finalDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            formatter.timeZone = TimeZone.current
            let dateString = formatter.string(from: finalDate)
            commitArgs.append("--date=\(dateString)")
        }

        // Create the commit
        try await GitWrapper.run(
            arguments: commitArgs,
            workingDirectory: fileManager.workingDirectory,
        )
    }
}
