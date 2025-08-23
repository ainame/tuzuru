import Foundation
import Mustache
import System

struct PageRenderer {
    private let templates: LoadedTemplates

    init(templates: LoadedTemplates) {
        self.templates = templates
    }

    func render(_ data: ArticleData) throws -> String {
        templates.article.render(data.render())
    }

    func render(_ data: ArticlePageLayoutData) throws -> String {
        templates.layout.render(data.render())
    }

    func render(_ data: [ListItemData]) throws -> String {
        templates.list.render([
            "articles": data.map { $0.render() }
        ])
    }

    func render(_ data: ListPageLayoutData) throws -> String {
        templates.list.render(data.render())
    }
}
