import Foundation
import System

public struct Article: Hashable {
    public let path: FilePath
    public var title: String
    public var author: String
    public var publishedAt: Date
    public var content: String
    public var htmlContent: String

    public init(path: FilePath, title: String, author: String, publishedAt: Date, content: String = "", htmlContent: String = "") {
        self.path = path
        self.title = title
        self.author = author
        self.publishedAt = publishedAt
        self.content = content
        self.htmlContent = htmlContent
    }
}