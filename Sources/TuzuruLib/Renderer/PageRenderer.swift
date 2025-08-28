import Foundation
import Mustache
import System

struct PageRenderer {
    private let library: MustacheLibrary

    init(templates: LoadedTemplates) {
        self.library = MustacheLibrary(templates: [
            "layout": templates.layout,
            "list": templates.list,
            "article": templates.article,
        ])
    }

    func render<Content: PageRendererable>(_ data: LayoutData<Content>) throws -> String {
        print(data.render())
        return library.render(data.render(), withTemplate: "layout")!
    }
}
