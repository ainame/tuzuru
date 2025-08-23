import Foundation
import System

/// Output file and directory configuration
/// Output style for generated HTML files
public enum OutputStyle: Sendable, CaseIterable {
    /// Direct HTML files (e.g., "about.html")
    case direct
    /// Subdirectory with index.html (e.g., "about/index.html" for clean URLs)
    case subdirectory
}

public struct OutputConfiguration: Sendable {
    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String

    /// Index page filename (e.g., "index.html")
    public let indexFileName: String

    /// Output style for generated pages
    public let style: OutputStyle

    public init(directory: String, indexFileName: String, style: OutputStyle) {
        self.directory = directory
        self.indexFileName = indexFileName
        self.style = style
    }
}
