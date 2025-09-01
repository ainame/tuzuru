import Foundation
import Testing

@testable import TuzuruLib

final class GitRepositoryFixture: @unchecked Sendable {
    let path: FilePath
    let fileManager: FileManager

    init(fileManager: FileManager) async throws {
        self.fileManager = fileManager

        let tempDir = fileManager.temporaryDirectory
        let uniqueDir = tempDir.appendingPathComponent(UUID().uuidString)
        self.path = FilePath(uniqueDir.path)

        try fileManager.createDirectory(at: uniqueDir, withIntermediateDirectories: true)
        try await setupGitRepository()
    }

    func clear() {
        try? fileManager.removeItem(atPath: path.string)
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
    }

    func copyFixtures(from sourcePath: FilePath) throws {
        let enumerator = fileManager.enumerator(atPath: sourcePath.string)

        while let relativePath = enumerator?.nextObject() as? String {
            let sourceFile = sourcePath.appending(relativePath)
            let destFile = path.appending(relativePath)

            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: sourceFile.string, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try fileManager.createDirectory(
                        atPath: destFile.string,
                        withIntermediateDirectories: true,
                    )
                } else {
                    let destDir = destFile.removingLastComponent()
                    try fileManager.createDirectory(
                        atPath: destDir.string,
                        withIntermediateDirectories: true,
                    )
                    try fileManager.copyItem(atPath: sourceFile.string, toPath: destFile.string)
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
        let fullPath = path.appending(fileName)
        if fileManager.fileExists(atPath: fullPath.string) {
            let existingContent = try String(contentsOfFile: fullPath.string, encoding: .utf8)
            let newContent = existingContent + "\n"
            try newContent.write(toFile: fullPath.string, atomically: true, encoding: .utf8)
        }

        let message = "[tuzuru amend] Updated \(field) for \(fileName)"
        try await createCommit(message: message, files: [fileName])
    }

    func writeFile(at relativePath: String, content: String) throws {
        let fullPath = path.appending(relativePath)
        let directory = fullPath.removingLastComponent()
        try fileManager.createDirectory(atPath: directory.string, withIntermediateDirectories: true)
        try content.write(toFile: fullPath.string, atomically: true, encoding: .utf8)
    }

    func readFile(at relativePath: String) throws -> String {
        let fullPath = path.appending(relativePath)
        return try String(contentsOfFile: fullPath.string, encoding: .utf8)
    }
}
