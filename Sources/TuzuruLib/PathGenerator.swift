import Foundation
import System

/// Generates paths and URLs based on output configuration
public struct PathGenerator: Sendable {
    private let configuration: OutputOptions
    
    public init(configuration: OutputOptions) {
        self.configuration = configuration
    }
    
    /// Generate output file path for a page based on its source path and style
    public func generateOutputPath(for pagePath: FilePath) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"
        
        switch configuration.style {
        case .direct:
            return "\(stem).html"
        case .subdirectory:
            return "\(stem)/index.html"
        }
    }
    
    /// Generate clean URL for linking to a page (used in templates)
    public func generateURL(for pagePath: FilePath) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"
        
        switch configuration.style {
        case .direct:
            return "\(stem).html"
        case .subdirectory:
            return "\(stem)/"
        }
    }
    
    /// Generate home page URL for blog title link (context-aware)
    public func generateHomeURL(from pagePath: FilePath? = nil) -> String {
        switch configuration.style {
        case .direct:
            return configuration.indexFileName
        case .subdirectory:
            // If we're generating for an article page (in a subdirectory), go up one level
            if pagePath != nil {
                return "../"
            } else {
                // For the index page itself
                return "./"
            }
        }
    }
}
