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

        let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
        let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
        let relativeDirComponents = Array(relativeComponents.dropLast())

        switch configuration.routingStyle {
        case .direct:
            if relativeDirComponents.isEmpty {
                return "\(stem).html"
            } else {
                let directoryPath = makeURLPath(from: relativeDirComponents)
                return "\(directoryPath)/\(stem).html"
            }
        case .subdirectory:
            if relativeDirComponents.isEmpty {
                return "\(stem)/index.html"
            } else {
                let directoryPath = makeURLPath(from: relativeDirComponents)
                return "\(directoryPath)/\(stem)/index.html"
            }
        }
    }

    /// Generate clean URL for linking to a page (used in templates)
    public func generateUrl(for pagePath: FilePath, isUnlisted: Bool = false) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"

        let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
        let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
        let relativeDirComponents = Array(relativeComponents.dropLast())

        switch configuration.routingStyle {
        case .direct:
            if relativeDirComponents.isEmpty {
                return "\(stem).html"
            } else {
                let directoryPath = makeURLPath(from: relativeDirComponents)
                return "\(directoryPath)/\(stem).html"
            }
        case .subdirectory:
            if relativeDirComponents.isEmpty {
                return "\(stem)/"
            } else {
                let directoryPath = makeURLPath(from: relativeDirComponents)
                return "\(directoryPath)/\(stem)/"
            }
        }
    }

    /// Generate home page URL for blog title link (context-aware)
    public func generateHomeUrl(from pagePath: FilePath? = nil, isUnlisted: Bool = false) -> String {
        switch configuration.routingStyle {
        case .direct:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
                let relativeDirComponents = Array(relativeComponents.dropLast())
                let depth = relativeDirComponents.count
                if depth > 0 {
                    return String(repeating: "../", count: depth) + configuration.indexFileName
                }
            }
            return configuration.indexFileName
        case .subdirectory:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
                let relativeDirComponents = Array(relativeComponents.dropLast())
                let depth = relativeDirComponents.count + 1
                return String(repeating: "../", count: depth)
            } else {
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
                let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
                let relativeDirComponents = Array(relativeComponents.dropLast())
                let depth = relativeDirComponents.count
                if depth > 0 {
                    return String(repeating: "../", count: depth) + "assets/"
                }
            }
            return "assets/"
        case .subdirectory:
            if let pagePath = pagePath {
                let basePath = isUnlisted ? unlistedBasePath : contentsBasePath
                let relativeComponents = getRelativePathComponents(from: basePath, to: pagePath)
                let relativeDirComponents = Array(relativeComponents.dropLast())
                let depth = relativeDirComponents.count + 1
                return String(repeating: "../", count: depth) + "assets/"
            } else {
                return "assets/"
            }
        }
    }

    /// Generate absolute URL using baseUrl and relative path
    public func generateAbsoluteUrl(baseUrl: String, relativePath: String) -> String {
        if baseUrl.isEmpty {
            return relativePath
        }

        let cleanBaseUrl = baseUrl.hasSuffix("/") ? String(baseUrl.dropLast()) : baseUrl
        let cleanRelativePath = relativePath.hasPrefix("/") ? relativePath : "/" + relativePath

        return cleanBaseUrl + cleanRelativePath
    }

    /// Calculate relative path components from base to target
    private func getRelativePathComponents(from base: FilePath, to target: FilePath) -> [FilePath.Component] {
        let baseComponents = Array(base.components)
        let targetComponents = Array(target.components)

        let commonLength = zip(baseComponents, targetComponents)
            .prefix { $0 == $1 }
            .count

        return Array(targetComponents.dropFirst(commonLength))
    }

    private func makeURLPath(from components: [FilePath.Component]) -> String {
        components.map(\.string).joined(separator: "/")
    }
}
