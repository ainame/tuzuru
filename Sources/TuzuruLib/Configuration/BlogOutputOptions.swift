import Foundation

public struct BlogOutputOptions: Sendable, Codable {
    /// Output file and directory configuration
    /// Output style for generated HTML files
    public enum OutputStyle: String, Sendable, CaseIterable, Codable {
        /// Direct HTML files (e.g., "about.html")
        case direct
        /// Subdirectory with index.html (e.g., "about/index.html" for clean URLs)
        case subdirectory
    }

    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String

    /// Output style for generated pages
    public let style: OutputStyle

    public init(directory: String, style: OutputStyle) {
        self.directory = directory
        self.style = style
    }

    /// Index page filename is always "index.html"
    public var indexFileName: String {
        "index.html"
    }
}
