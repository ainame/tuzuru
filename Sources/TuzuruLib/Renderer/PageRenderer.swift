import Foundation
import Mustache

struct PageRenderer {
    private let library: MustacheLibrary

    init(templates: LoadedTemplates) {
        self.library = MustacheLibrary(templates: [
            "layout": templates.layout,
            "list": templates.list,
            "post": templates.post,
        ])
    }

    func render<Content: PageRendererable>(_ data: LayoutData<Content>) throws -> String {
        library.render(data.render(), withTemplate: "layout")!
    }
}
