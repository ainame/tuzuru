import Foundation
import Mustache

/// Represents a source with raw (unprocessed) posts and metadata
public struct RawSource: Sendable {
    public var metadata: BlogMetadata
    public var posts: [RawPost]
    public var years: [String]
    public var categories: [String]
    var templates: MustacheLibrary

    init(
        metadata: BlogMetadata,
        templates: MustacheLibrary,
        posts: [RawPost],
        years: [String],
        categories: [String]
    ) {
        self.metadata = metadata
        self.templates = templates
        self.posts = posts
        self.years = years
        self.categories = categories
    }
}
