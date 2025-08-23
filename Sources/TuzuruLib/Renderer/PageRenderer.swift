import Foundation
import Mustache
import System

struct PageRenderer {
    private struct LoadedTemplates {
        let layout: MustacheTemplate
        let article: MustacheTemplate
        let list: MustacheTemplate
    }

    private let templates: LoadedTemplates

    init(templates: Templates) throws {
        self.templates = try Self.loadTemplates(templates: templates)
    }

    func render(_ data: ArticleData) throws -> String {
        templates.article.render(data.render())
    }

    func render(_ data:ArticlePageLayoutData) throws -> String {
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

    private static func loadTemplates(templates: Templates) throws -> LoadedTemplates {
        let fileManager = FileManager()
        guard let layoutData = fileManager.contents(atPath: templates.layoutFile),
              let layoutTemplate = String(data: layoutData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.layoutFile)
        }

        guard let articleData = fileManager.contents(atPath: templates.articleFile),
              let articleTemplate = String(data: articleData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.articleFile)
        }

        guard let listData = fileManager.contents(atPath: templates.listFile),
              let listTemplate = String(data: listData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.listFile)
        }
        return try LoadedTemplates(
            layout: MustacheTemplate(string: layoutTemplate),
            article: MustacheTemplate(string: articleTemplate),
            list: MustacheTemplate(string: listTemplate),
        )
    }
}
