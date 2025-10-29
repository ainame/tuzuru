import Foundation

public struct GenerateManifest: Codable, Sendable {
    public let generatedAt: TimeInterval
    public let sourceDirs: [String: TimeInterval]
    public let files: [String]

    public init(sourceDirs: [FilePath], generatedFiles: [FilePath], fileManager: FileManagerWrapper) throws {
        self.generatedAt = Date().timeIntervalSince1970

        var dirTimestamps: [String: TimeInterval] = [:]
        for dir in sourceDirs where fileManager.fileExists(atPath: dir) {
            let attributes = try fileManager.attributesOfItem(atPath: dir)
            if let modificationDate = attributes[.modificationDate] as? Date {
                dirTimestamps[dir.string] = modificationDate.timeIntervalSince1970
            }
        }
        self.sourceDirs = dirTimestamps
        self.files = generatedFiles.map(\.string)
    }

    /// Check if the manifest is stale compared to current directory timestamps
    public func isStale(currentDirs: [FilePath], fileManager: FileManagerWrapper) -> Bool {
        for dir in currentDirs {
            guard fileManager.fileExists(atPath: dir) else { continue }

            do {
                let attributes = try fileManager.attributesOfItem(atPath: dir)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    let currentTime = modificationDate.timeIntervalSince1970
                    let manifestTime = sourceDirs[dir.string] ?? 0
                    if currentTime > manifestTime {
                        return true
                    }
                }
            } catch {
                // If we can't read the directory, consider it stale to be safe
                return true
            }
        }
        return false
    }

    /// Get list of files that exist in manifest but not in current generated files
    public func getOrphanedFiles(currentFiles: [String]) -> [String] {
        return files.filter { !currentFiles.contains($0) }
    }

    /// Save manifest to specified path
    public func save(to path: FilePath, fileManager: FileManagerWrapper) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(self)

        // Create .build directory if it doesn't exist
        let buildDir = path.removingLastComponent()
        if !fileManager.fileExists(atPath: buildDir) {
            try fileManager.createDirectory(atPath: buildDir, withIntermediateDirectories: true)
        }

        _ = fileManager.createFile(atPath: path, contents: data)
    }

    /// Load manifest from specified path
    public static func load(from path: FilePath, fileManager: FileManagerWrapper) throws -> GenerateManifest? {
        guard fileManager.fileExists(atPath: path) else {
            return nil
        }

        guard let data = fileManager.contents(atPath: path) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try decoder.decode(GenerateManifest.self, from: data)
    }
}
