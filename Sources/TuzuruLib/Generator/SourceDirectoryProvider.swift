import Foundation

struct SourceDirectoryProvider: Sendable {
    private let fileManager: FileManagerWrapper
    private let configuration: BlogConfiguration

    init(fileManager: FileManagerWrapper, configuration: BlogConfiguration) {
        self.fileManager = fileManager
        self.configuration = configuration
    }

    /// Get all source directories (contents + unlisted) for change detection
    func getSourceDirectories() -> [FilePath] {
        return [
            fileManager.workingDirectory.appending(configuration.sourceLayout.contents.string),
            fileManager.workingDirectory.appending(configuration.sourceLayout.unlisted.string),
        ]
    }

    /// Get all tracked directories (contents + unlisted + assets) for integrity management
    func getTrackedDirectories() -> [FilePath] {
        return [
            fileManager.workingDirectory.appending(configuration.sourceLayout.contents.string),
            fileManager.workingDirectory.appending(configuration.sourceLayout.unlisted.string),
            fileManager.workingDirectory.appending(configuration.sourceLayout.assets.string),
        ].filter { fileManager.fileExists(atPath: $0) }
    }

    /// Get assets directory path
    func getAssetsDirectory() -> FilePath {
        return fileManager.workingDirectory.appending("assets")
    }
}
