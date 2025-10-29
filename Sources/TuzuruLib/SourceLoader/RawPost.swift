import Foundation

/// Represents a post with raw markdown content before processing
public struct RawPost: Sendable, Hashable {
    public let path: FilePath
    public var author: String
    public var publishedAt: Date
    public var content: String        // Raw markdown content
    public var isUnlisted: Bool

    public init(
        path: FilePath,
        author: String,
        publishedAt: Date,
        content: String,
        isUnlisted: Bool = false
    ) {
        self.path = path
        self.author = author
        self.publishedAt = publishedAt
        self.content = content
        self.isUnlisted = isUnlisted
    }
}
