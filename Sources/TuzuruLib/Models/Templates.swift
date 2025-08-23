import Foundation
import System

/// Template file configuration
struct Templates: Sendable, Equatable {
    /// Layout template file path (e.g., "layout.html.mustache")
    let layoutFile: String
    
    /// Article template file path (e.g., "article.html.mustache")
    let articleFile: String
    
    /// List template file path (e.g., "list.html.mustache")
    let listFile: String
    
    init(layoutFile: String, articleFile: String, listFile: String) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
}
