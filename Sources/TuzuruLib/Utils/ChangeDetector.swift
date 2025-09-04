import Foundation

/// ChangeDetector see if any changes were made in `contents/` from give path for `blog/` since the late request time.
/// This powers `tuzuru serve` command to trigger regeneration only when needed.
struct ChangeDetector: Sendable {
    private let fileManager: FileManagerWrapper
    private let sourceDirectoryProvider: SourceDirectoryProvider

    init(fileManager: FileManagerWrapper, configuration: BlogConfiguration) {
        self.fileManager = fileManager
        self.sourceDirectoryProvider = SourceDirectoryProvider(fileManager: fileManager, configuration: configuration)
    }

    /// Check if regeneration is needed based on file changes
    func checkIfChangesMade(
        at requestPath: String,
        since lastRequestTime: Date,
        in pathMapping: [String: FilePath]
    ) -> Bool {
        // Check if any source files in contents directory have changed (additions/deletions/modifications)
        if hasSourceFilesChanged(since: lastRequestTime) {
            return true
        }

        // Check if any asset files have changed
        if hasAssetFilesChanged(since: lastRequestTime) {
            return true
        }

        // Check if the specific mapped file has changed (for targeted updates)
        if let sourcePath = pathMapping[requestPath] {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: sourcePath)
                if let modificationDate = attributes[.modificationDate] as? Date {
                    return modificationDate > lastRequestTime
                }
            } catch {
                print("Warning: Could not get modification date for \(sourcePath): \(error)")
            }
        }

        return false
    }

    /// Check if source files have changed since the given time
    private func hasSourceFilesChanged(since lastRequestTime: Date) -> Bool {
        let sourceDirectories = sourceDirectoryProvider.getSourceDirectories()

        for directoryPath in sourceDirectories {
            if hasDirectoryChanged(directoryPath, since: lastRequestTime) {
                return true
            }
        }

        return false
    }

    /// Check if asset files have changed since the given time
    private func hasAssetFilesChanged(since lastRequestTime: Date) -> Bool {
        let assetsPath = sourceDirectoryProvider.getAssetsDirectory()
        return hasDirectoryChanged(assetsPath, since: lastRequestTime)
    }

    /// Check if a directory has changed since the given time
    private func hasDirectoryChanged(_ directoryPath: FilePath, since lastRequestTime: Date) -> Bool {
        guard fileManager.fileExists(atPath: directoryPath) else {
            return false
        }

        // Check directory modification time first (indicates file additions/deletions)
        do {
            let dirAttributes = try fileManager.attributesOfItem(atPath: directoryPath)
            if let dirModificationDate = dirAttributes[.modificationDate] as? Date,
               dirModificationDate > lastRequestTime {
                return true
            }
        } catch {
            print("Warning: Could not get modification date for directory \(directoryPath): \(error)")
        }

        // Recursively check all files in the directory
        guard let enumerator = fileManager.enumerator(atPath: directoryPath) else {
            return false
        }

        for case let filePathString as String in enumerator {
            let fullPath = directoryPath.appending(filePathString)

            do {
                let attributes = try fileManager.attributesOfItem(atPath: fullPath)
                if let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate > lastRequestTime {
                    return true
                }
            } catch {
                // File might have been deleted during enumeration, continue
                continue
            }
        }

        return false
    }
}
