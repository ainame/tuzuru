import Foundation
import System

/// Template file configuration
public struct TemplateConfiguration: Sendable {
    /// Layout template file path (e.g., "layout.mustache")
    public let layoutFile: String
    
    /// Article template file path (e.g., "article.html")
    public let articleFile: String
    
    /// List template file path (e.g., "list.html")
    public let listFile: String
    
    public init(layoutFile: String, articleFile: String, listFile: String) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
}

