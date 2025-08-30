import Foundation
import Mustache

public struct Source: Sendable {
    public var metadata: BlogMetadata
    public var posts: [Post]
    public var years: [String]
    public var categories: [String]
    var templates: MustacheLibrary

    init(metadata: BlogMetadata, templates: MustacheLibrary, posts: [Post], years: [String] = [], categories: [String] = []) {
        self.metadata = metadata
        self.templates = templates
        self.posts = posts
        self.years = years
        self.categories = categories
    }
}
