import Foundation

/// Resolves category information from post file paths within the blog's contents directory.
///
/// This resolver understands the blog's directory structure and applies Tuzuru's
/// category rules (e.g., excluding the 'imported' directory from category listings).
struct CategoryResolver {
    private let contentsBasePath: FilePath
    private let importedDirName: String

    init(contentsBasePath: FilePath, importedDirName: String = "imported") {
        self.contentsBasePath = contentsBasePath
        self.importedDirName = importedDirName
    }

    /// Extract the top-level directory (category) from a post path
    /// Returns nil if the post is in the contents root or the path is invalid
    func extractCategory(from postPath: FilePath) -> String? {
        guard let topLevelDir = extractTopLevelDirectory(from: postPath) else {
            return nil
        }

        // Skip imported directory
        if topLevelDir == importedDirName {
            return nil
        }

        return topLevelDir
    }

    /// Extract the top-level directory from a post path without filtering
    /// Returns nil if the post is in the contents root or the path is invalid
    func extractTopLevelDirectory(from postPath: FilePath) -> String? {
        // Get relative components by removing the base path components
        // These components include the filename, so we need at least 2 components
        // to have a directory: [directory, filename]
        let relativeComponents = getRelativeComponents(from: postPath)

        // Need at least 2 components: directory + filename
        guard relativeComponents.count >= 2 else {
            return nil
        }

        // Return the first component (the directory)
        return relativeComponents.first?.string
    }

    // MARK: - Private Methods

    /// Get path components relative to the contents base path
    private func getRelativeComponents(from postPath: FilePath) -> [FilePath.Component] {
        let baseComponents = Array(contentsBasePath.components)
        let postComponents = Array(postPath.components)

        // Verify the post path starts with the base path
        guard postComponents.count > baseComponents.count else {
            return []
        }

        // Check if base path is a prefix
        let basePrefix = postComponents.prefix(baseComponents.count)
        guard basePrefix.elementsEqual(baseComponents) else {
            return []
        }

        // Return components after the base path
        return Array(postComponents.dropFirst(baseComponents.count))
    }
}
