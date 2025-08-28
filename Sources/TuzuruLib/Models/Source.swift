import Foundation
import System

public struct Source: Sendable {
    public var metadata: BlogMetadata
    var templates: LoadedTemplates
    public var posts: [Post]

    init(metadata: BlogMetadata, templates: LoadedTemplates, posts: [Post]) {
        self.metadata = metadata
        self.templates = templates
        self.posts = posts
    }
}
