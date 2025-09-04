import Foundation

/// IntegrityManager keeps the output directory `blog/` in sync wtih `contents/` by monitoring
/// timestamps on each source directory. When renaming or deletion of files occur, this will perform cleanup.
struct IntegrityManager: Sendable {
    private let fileManager: FileManagerWrapper
    private let blogConfiguration: BlogConfiguration
    private let sourceDirectoryProvider: SourceDirectoryProvider

    init(fileManager: FileManagerWrapper, blogConfiguration: BlogConfiguration) {
        self.fileManager = fileManager
        self.blogConfiguration = blogConfiguration
        self.sourceDirectoryProvider = SourceDirectoryProvider(fileManager: fileManager, configuration: blogConfiguration)
    }


    /// Get the path to the manifest file in .build
    var manifestPath: FilePath {
        fileManager.workingDirectory.appending(".build/manifest.json")
    }

    /// Get source directories to track for changes
    var sourceDirectoriesToTrack: [FilePath] {
        sourceDirectoryProvider.getTrackedDirectories()
    }

    /// Load existing manifest if it exists
    func loadExistingManifest() throws -> GenerateManifest? {
        try GenerateManifest.load(from: manifestPath, fileManager: fileManager)
    }

    /// Check if integrity cleanup is needed based on manifest staleness
    func isCleanupNeeded() throws -> Bool {
        guard let manifest = try loadExistingManifest() else {
            // No manifest exists, no cleanup needed (first run)
            return false
        }

        let currentDirs = sourceDirectoriesToTrack
        return manifest.isStale(currentDirs: currentDirs, fileManager: fileManager)
    }

    /// Perform integrity cleanup by removing orphaned files
    func performCleanup(with existingManifest: GenerateManifest, newGeneratedFiles: [FilePath]) throws {
        let blogRoot = FilePath(blogConfiguration.output.directory)
        let newFileList = newGeneratedFiles.map(\.string)
        let orphanedFiles = existingManifest.getOrphanedFiles(currentFiles: newFileList)

        var deletedCount = 0
        var errorCount = 0

        for orphanedFile in orphanedFiles {
            let filePath = FilePath(orphanedFile)

            // Safety check: only delete files that look like tuzuru-generated files
            guard isSafeToDelete(filePath: filePath, blogRoot: blogRoot) else {
                print("Skipping deletion of potentially user-added file: \(orphanedFile)")
                continue
            }

            do {
                if fileManager.fileExists(atPath: filePath) {
                    try fileManager.removeItem(atPath: filePath)
                    print("Deleted orphaned file: \(orphanedFile)")
                    deletedCount += 1

                    // Clean up empty directories if possible
                    try cleanupEmptyDirectory(filePath.removingLastComponent(), blogRoot: blogRoot)
                }
            } catch {
                print("Error deleting file \(orphanedFile): \(error)")
                errorCount += 1
            }
        }

        if deletedCount > 0 || errorCount > 0 {
            print("Integrity cleanup completed: \(deletedCount) files deleted, \(errorCount) errors")
        }
    }

    /// Create and save a new manifest after successful generation
    func saveNewManifest(generatedFiles: [FilePath]) throws {
        let sourceDirs = sourceDirectoriesToTrack
        let manifest = try GenerateManifest(
            sourceDirs: sourceDirs,
            generatedFiles: generatedFiles,
            fileManager: fileManager
        )
        try manifest.save(to: manifestPath, fileManager: fileManager)
    }

    /// Safety check to ensure we only delete files that look like tuzuru-generated content
    private func isSafeToDelete(filePath: FilePath, blogRoot: FilePath) -> Bool {
        let fileString = filePath.string
        let blogRootString = blogRoot.string

        // Must be within blog directory
        guard fileString.hasPrefix(blogRootString) else {
            return false
        }

        // Allow deletion of:
        // - .html files (posts and list pages)
        // - Files in year directories (e.g., 2024/index.html)
        // - Files in content category directories
        // - sitemap.xml

        let fileName = filePath.lastComponent?.string ?? ""
        let relativePath = String(fileString.dropFirst(blogRootString.count + 1))

        // Allow sitemap.xml
        if fileName == "sitemap.xml" {
            return true
        }

        // Allow .html files
        if fileName.hasSuffix(".html") {
            return true
        }

        // Allow files in numeric year directories (e.g., 2024/, 2023/)
        let pathComponents = relativePath.split(separator: "/")
        if let firstComponent = pathComponents.first,
           firstComponent.allSatisfy(\.isNumber) && firstComponent.count == 4 {
            return true
        }

        // Allow files in category directories (but not assets or other special dirs)
        // This is a bit heuristic, but we avoid deleting from "assets" or other known special dirs
        if !relativePath.hasPrefix("assets/") && fileName.hasSuffix(".html") {
            return true
        }

        return false
    }

    /// Try to clean up an empty directory (but don't fail if it's not empty)
    private func cleanupEmptyDirectory(_ directoryPath: FilePath, blogRoot: FilePath) throws {
        // Don't remove the blog root directory itself
        guard directoryPath != blogRoot else { return }

        // Only clean up directories within blog root
        guard directoryPath.string.hasPrefix(blogRoot.string) else { return }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            if contents.isEmpty {
                try fileManager.removeItem(atPath: directoryPath)
                print("Removed empty directory: \(directoryPath.string)")
            }
        } catch {
            // If we can't read or remove the directory, that's fine - it might not be empty
            // or we might not have permissions. This is not a critical error.
        }
    }
}
