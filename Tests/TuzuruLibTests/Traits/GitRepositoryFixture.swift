import Foundation
import Testing

@testable import TuzuruLib

final class GitRepositoryFixture: @unchecked Sendable {
    let path: FilePath
    let fileManager: FileManagerWrapper

    init() async throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let uniqueDir = tempDir.appendingPathComponent(UUID().uuidString)
        self.path = FilePath(uniqueDir.path)
        self.fileManager = FileManagerWrapper(workingDirectory: self.path)

        try fileManager.createDirectory(atPath: self.path, withIntermediateDirectories: true)
        try await setupGitRepository()
    }

    func clear() {
        try? fileManager.removeItem(atPath: path)
    }

    private func setupGitRepository() async throws {
        // Initialize git repository
        try await GitWrapper.run(arguments: ["init"], workingDirectory: path)

        // Configure git user for testing
        try await GitWrapper.run(
            arguments: ["config", "user.name", "Test User"],
            workingDirectory: path,
        )
        try await GitWrapper.run(
            arguments: ["config", "user.email", "test@example.com"],
            workingDirectory: path,
        )

        // Set initial branch to main
        try await GitWrapper.run(
            arguments: ["checkout", "-b", "main"],
            workingDirectory: path,
        )

        // Create initial commit to establish repository state
        _ = fileManager.createFile(atPath: FilePath(".gitkeep"), contents: Data())
        try await GitWrapper.run(
            arguments: ["add", ".gitkeep"],
            workingDirectory: path
        )
        try await GitWrapper.run(
            arguments: ["commit", "-m", "Initial repository setup"],
            workingDirectory: path
        )
    }

    func copyFixtures(from sourcePath: FilePath) throws {
        // Use FileManager.default for source operations since sourcePath is absolute
        let sourceManager = FileManager.default
        let enumerator = sourceManager.enumerator(atPath: sourcePath.string)

        while let relativePath = enumerator?.nextObject() as? String {
            let sourceFile = sourcePath.appending(relativePath)
            let destFile = FilePath(relativePath)

            var isDirectory: ObjCBool = false
            if sourceManager.fileExists(atPath: sourceFile.string, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try fileManager.createDirectory(
                        atPath: destFile,
                        withIntermediateDirectories: true
                    )
                } else {
                    let destDir = destFile.removingLastComponent()
                    try fileManager.createDirectory(
                        atPath: destDir,
                        withIntermediateDirectories: true
                    )
                    // Copy from absolute source path to relative dest path
                    try sourceManager.copyItem(atPath: sourceFile.string, toPath: fileManager.workingDirectory.appending(destFile.string).string)
                }
            }
        }
    }

    func createCommit(message: String, files: [String] = []) async throws {
        // Add files to git
        if files.isEmpty {
            try await GitWrapper.run(arguments: ["add", "."], workingDirectory: path)
        } else {
            for file in files {
                try await GitWrapper.run(arguments: ["add", file], workingDirectory: path)
            }
        }

        // Create commit
        try await GitWrapper.run(
            arguments: ["commit", "-m", message],
            workingDirectory: path,
        )
    }

    func createMarkerCommit(for fileName: String, field: String) async throws {
        // Add a minimal change to the file (like FileAmender does)
        let filePath = FilePath(fileName)
        if fileManager.fileExists(atPath: filePath) {
            let existingContent = fileManager.contents(atPath: filePath) ?? Data()
            let existingString = String(data: existingContent, encoding: .utf8) ?? ""
            let newContent = existingString + "\n"
            _ = fileManager.createFile(atPath: filePath, contents: newContent.data(using: .utf8) ?? Data())
        }

        let message = "[tuzuru amend] Updated \(field) for \(fileName)"
        try await createCommit(message: message, files: [fileName])
    }

    func writeFile(at relativePath: String, content: String) throws {
        let fullPath = path.appending(relativePath)
        let directory = fullPath.removingLastComponent()
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        try content.write(toFile: fullPath.string, atomically: true, encoding: .utf8)
    }

    func readFile(at relativePath: String) throws -> String {
        let fullPath = path.appending(relativePath)
        return try String(contentsOfFile: fullPath.string, encoding: .utf8)
    }
}
