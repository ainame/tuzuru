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
    
    /// Convenience initializer for backward compatibility
    public init(directory: String, indexFileName: String, pageExtension: String) {
        self.directory = directory
        self.indexFileName = indexFileName
        self.style = .direct
    }
    
    /// Generate output path for a page based on its source path and style
    public func generateOutputPath(for pagePath: FilePath) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"
        
        switch style {
        case .direct:
            return "\(stem).html"
        case .subdirectory:
            return "\(stem)/index.html"
        }
    }
    
    /// Generate filename for a page based on its path (deprecated, use generateOutputPath)
    public func generateFileName(for pagePath: FilePath) -> String {
        return generateOutputPath(for: pagePath)
    }
}
