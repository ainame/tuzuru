import Foundation
import System
import Mustache

/// Handles template processing and site generation
struct SiteGenerator {
    private let fileManager: FileManager
    private let markdownProcessor: MarkdownProcessor
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.markdownProcessor = MarkdownProcessor()
    }
    
    func generate(_ source: Source) throws -> SiteLayout {
        let siteRoot = FilePath("site")
        
        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: siteRoot.string, withIntermediateDirectories: true)
        
        // Load templates
        let templates = try loadTemplates(source: source)
        
        // Generate individual article pages
        for page in source.pages {
            try generateArticlePage(
                page: page,
                layoutTemplate: templates.layout,
                articleTemplate: templates.article,
                siteRoot: siteRoot
            )
        }
        
        // Generate list page (index.html)
        try generateListPage(
            pages: source.pages,
            layoutTemplate: templates.layout,
            listTemplate: templates.list,
            siteRoot: siteRoot
        )
        
        return SiteLayout(
            root: siteRoot,
            contents: siteRoot,
            assets: siteRoot
        )
    }
    
    // MARK: - Private Methods
    
    private struct Templates {
        let layout: String
        let article: String
        let list: String
    }
    
    private func loadTemplates(source: Source) throws -> Templates {
        guard let layoutData = fileManager.contents(atPath: source.layoutFile.string),
              let layoutTemplate = String(data: layoutData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(source.layoutFile.string)
        }
        
        guard let articleData = fileManager.contents(atPath: "article.html"),
              let articleTemplate = String(data: articleData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound("article.html")
        }
        
        guard let listData = fileManager.contents(atPath: "list.html"),
              let listTemplate = String(data: listData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound("list.html")
        }
        
        return Templates(
            layout: layoutTemplate,
            article: articleTemplate,
            list: listTemplate
        )
    }
    
    private func generateArticlePage(
        page: Page,
        layoutTemplate: String,
        articleTemplate: String,
        siteRoot: FilePath
    ) throws {
        // Prepare data for article template
        let articleData: [String: Any] = [
            "title": page.title,
            "author": page.author,
            "publishedAt": formatDate(page.publishedAt),
            "body": page.htmlContent
        ]
        
        // Render article template
        let articleMustacheTemplate = try MustacheTemplate(string: articleTemplate)
        let renderedArticle = articleMustacheTemplate.render(articleData)
        
        // Prepare data for layout template
        let layoutData: [String: Any] = [
            "title": page.title,
            "blog_title": "My Blog",
            "content": renderedArticle
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write to file
        let fileName = "\(page.path.lastComponent?.stem ?? "untitled").html"
        let outputPath = siteRoot.appending(fileName)
        try finalHTML.write(to: URL(fileURLWithPath: outputPath.string), atomically: true, encoding: .utf8)
    }
    
    private func generateListPage(
        pages: [Page],
        layoutTemplate: String,
        listTemplate: String,
        siteRoot: FilePath
    ) throws {
        // Prepare articles data for list template
        let articlesData = pages.map { page -> [String: Any] in
            let articleURL = "\(page.path.lastComponent?.stem ?? "untitled").html"
            
            return [
                "title": page.title,
                "author": page.author,
                "publishedAt": formatDate(page.publishedAt),
                "url": articleURL,
                "excerpt": markdownProcessor.extractExcerpt(from: page.content)
            ]
        }
        
        let listData: [String: Any] = [
            "articles": articlesData
        ]
        
        // Render list template
        let listMustacheTemplate = try MustacheTemplate(string: listTemplate)
        let renderedList = listMustacheTemplate.render(listData)
        
        // Prepare data for layout template
        let layoutData: [String: Any] = [
            "title": "Blog",
            "blog_title": "My Blog",
            "content": renderedList
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write index.html
        let indexPath = siteRoot.appending("index.html")
        try finalHTML.write(to: URL(fileURLWithPath: indexPath.string), atomically: true, encoding: .utf8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}