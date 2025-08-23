import Foundation
import System

struct Source: Sendable, Equatable {
    var title: String
    var layoutFile: FilePath
    var pages: [Article]

    init(title: String, templates: FilePath, pages: [Article]) {
        self.title = title
        self.layoutFile = templates
        self.pages = pages
    }
}
