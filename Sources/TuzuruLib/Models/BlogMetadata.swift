import Foundation

/// Site metadata configuration
public struct BlogMetadata: Sendable {
    /// Blog title displayed in layouts
    public let blogName: String
    
    /// Copyright notice
    public let copyright: String

    public init(
        blogTitle: String,
        copyright: String,
    ) {
        self.blogName = blogTitle
        self.copyright = copyright
    }
}
