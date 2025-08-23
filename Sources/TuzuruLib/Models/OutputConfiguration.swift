import Foundation
import System

/// Output file and directory configuration
public struct OutputConfiguration: Sendable {
    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String
    
    /// Index page filename (e.g., "index.html")
    public let indexFileName: String
    
    /// File extension for generated pages (e.g., ".html")
    public let pageExtension: String
    
    public init(
        directory: String = "blog",
        indexFileName: String = "index.html",
        pageExtension: String = ".html"
    ) {
        self.directory = directory
        self.indexFileName = indexFileName
        self.pageExtension = pageExtension
    }
    
    /// Generate filename for a page based on its path
    public func generateFileName(for pagePath: FilePath) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"
        return "\(stem)\(pageExtension)"
    }
}
