import Foundation
import System

struct Source: Sendable, Equatable {
    var title: String
    var templates: Templates
    var pages: [Article]

    init(title: String, templates: Templates, pages: [Article]) {
        self.title = title
        self.templates = templates
        self.pages = pages
    }
}
