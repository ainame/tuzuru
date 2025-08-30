import Foundation

/// Generates paths and URLs based on output configuration
public struct PathGenerator: Sendable {
    private let configuration: BlogOutputOptions
    private let contentsBasePath: FilePath
    private let unlistedBasePath: FilePath

    public init(configuration: BlogOutputOptions, contentsBasePath: FilePath, unlistedBasePath: FilePath) {
        self.configuration = configuration
        self.contentsBasePath = contentsBasePath
        self.unlistedBasePath = unlistedBasePath
    }

    /// Generate output file path for a page based on its source path and style
    public func generateOutputPath(for pagePath: FilePath, isUnlisted: Bool = false) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"

        // Calculate relative path from appropriate base directory
        let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
        let relativePath = getRelativePath(from: basePath, to: pagePath)
        let relativeDir = relativePath.removingLastComponent()

        switch configuration.routingStyle {
        case .direct:
            if relativeDir.components.isEmpty {
                return "\(stem).html"
            } else {
                return "\(relativeDir.string)/\(stem).html"
            }
        case .subdirectory:
            if relativeDir.components.isEmpty {
                return "\(stem)/index.html"
            } else {
                return "\(relativeDir.string)/\(stem)/index.html"
            }
        }
    }

    /// Generate clean URL for linking to a page (used in templates)
    public func generateUrl(for pagePath: FilePath, isUnlisted: Bool = false) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"

        // Calculate relative path from appropriate base directory
        let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
        let relativePath = getRelativePath(from: basePath, to: pagePath)
        let relativeDir = relativePath.removingLastComponent()

        switch configuration.routingStyle {
        case .direct:
            if relativeDir.components.isEmpty {
                return "\(stem).html"
            } else {
                return "\(relativeDir.string)/\(stem).html"
            }
        case .subdirectory:
            if relativeDir.components.isEmpty {
                return "\(stem)/"
            } else {
                return "\(relativeDir.string)/\(stem)/"
            }
        }
    }

    /// Generate home page URL for blog title link (context-aware)
    public func generateHomeUrl(from pagePath: FilePath? = nil, isUnlisted: Bool = false) -> String {
        switch configuration.routingStyle {
        case .direct:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativePath = getRelativePath(from: basePath, to: pagePath)
                let relativeDir = relativePath.removingLastComponent()
                let depth = relativeDir.components.count
                if depth > 0 {
                    return String(repeating: "../", count: depth) + configuration.indexFileName
                }
            }
            return configuration.indexFileName
        case .subdirectory:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativePath = getRelativePath(from: basePath, to: pagePath)
                let relativeDir = relativePath.removingLastComponent()
                let depth = relativeDir.components.count + 1 // +1 for the post subdirectory
                return String(repeating: "../", count: depth)
            } else {
                // For the index page itself
                return "./"
            }
        }
    }

    /// Generate assets URL for CSS/JS/images (context-aware)
    public func generateAssetsUrl(from pagePath: FilePath? = nil, isUnlisted: Bool = false) -> String {
        switch configuration.routingStyle {
        case .direct:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativePath = getRelativePath(from: basePath, to: pagePath)
                let relativeDir = relativePath.removingLastComponent()
                let depth = relativeDir.components.count
                if depth > 0 {
                    return String(repeating: "../", count: depth) + "assets/"
                }
            }
            return "assets/"
        case .subdirectory:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativePath = getRelativePath(from: basePath, to: pagePath)
                let relativeDir = relativePath.removingLastComponent()
                let depth = relativeDir.components.count + 1 // +1 for the post subdirectory
                return String(repeating: "../", count: depth) + "assets/"
            } else {
                // For the index page itself
                return "assets/"
            }
        }
    }

    /// Calculate relative path from base to target
    private func getRelativePath(from base: FilePath, to target: FilePath) -> FilePath {
        let baseComponents = base.components
        let targetComponents = target.components

        // Find the common prefix length
        let commonLength = zip(baseComponents, targetComponents)
            .prefix { $0 == $1 }
            .count

        // Get the remaining components from the target path
        let relativeComponents = Array(targetComponents.dropFirst(commonLength))

        // Create path string from components
        let pathString = relativeComponents.map(\.string).joined(separator: "/")
        return FilePath(pathString)
    }
}
