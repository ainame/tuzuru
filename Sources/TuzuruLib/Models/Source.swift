import Foundation

public struct Source: Sendable {
    public var metadata: BlogMetadata
    public var posts: [Post]
    var templates: LoadedTemplates

    init(metadata: BlogMetadata, templates: LoadedTemplates, posts: [Post]) {
        self.metadata = metadata
        self.templates = templates
        self.posts = posts
    }
}
