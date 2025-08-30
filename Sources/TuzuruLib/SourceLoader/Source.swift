import Foundation
import Mustache

public struct Source: Sendable {
    public var metadata: BlogMetadata
    public var posts: [Post]
    var templates: MustacheLibrary

    init(metadata: BlogMetadata, templates: MustacheLibrary, posts: [Post]) {
        self.metadata = metadata
        self.templates = templates
        self.posts = posts
    }
}
