import Foundation
import System

/// Template file configuration
struct Templates: Sendable {
    /// Layout template file path (e.g., "layout.mustache")
    let layoutFile: String
    
    /// Article template file path (e.g., "article.html")
    let articleFile: String
    
    /// List template file path (e.g., "list.html")
    let listFile: String
    
    init(layoutFile: String, articleFile: String, listFile: String) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
}
