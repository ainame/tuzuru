import Foundation
import System

struct Article: Sendable, Hashable {
    let path: FilePath
    var title: String
    var author: String
    var publishedAt: Date
    var excerpt: String
    var content: String
    var htmlContent: String

    init(
        path: FilePath,
        title: String,
        author: String,
        publishedAt: Date,
        excerpt: String,
        content: String,
        htmlContent: String
    ) {
        self.path = path
        self.title = title
        self.author = author
        self.publishedAt = publishedAt
        self.excerpt = excerpt
        self.content = content
        self.htmlContent = htmlContent
    }
}
