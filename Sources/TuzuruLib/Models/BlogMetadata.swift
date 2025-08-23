import Foundation

/// Site metadata configuration
public struct BlogMetadata: Sendable {
    /// Blog title displayed in layouts
    public let blogTitle: String
    
    /// Copyright notice
    public let copyright: String
    
    /// Default page title for list pages
    public let listPageTitle: String
    
    public init(
        blogTitle: String,
        copyright: String,
        listPageTitle: String,
    ) {
        self.blogTitle = blogTitle
        self.copyright = copyright
        self.listPageTitle = listPageTitle
    }
}
