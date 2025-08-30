import Foundation
import Mustache

struct PageRenderer {
    private let templates: MustacheLibrary

    init(templates: MustacheLibrary) {
        self.templates = templates
    }

    func render<Content: PageRendererable>(_ data: LayoutData<Content>) throws -> String {
        templates.render(data.render(), withTemplate: "layout")!
    }
}
