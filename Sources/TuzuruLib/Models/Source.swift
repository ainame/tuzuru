import Foundation
import System

public struct Source: Sendable {
    public var title: String
    var templates: LoadedTemplates
    public var pages: [Article]

    init(title: String, templates: LoadedTemplates, pages: [Article]) {
        self.title = title
        self.templates = templates
        self.pages = pages
    }
}
