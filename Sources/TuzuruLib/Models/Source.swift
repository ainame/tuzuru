import Foundation
import System

public struct Source: Sendable {
    public var metadata: BlogMetadata
    var templates: LoadedTemplates
    public var articles: [Article]

    init(metadata: BlogMetadata, templates: LoadedTemplates, articles: [Article]) {
        self.metadata = metadata
        self.templates = templates
        self.articles = articles
    }
}
