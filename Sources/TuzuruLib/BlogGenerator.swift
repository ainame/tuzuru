import Foundation
import System
import Mustache

/// Handles template processing and site generation
struct BlogGenerator {
    private let fileManager: FileManager
    private let configuration: BlogConfiguration
    private let pathGenerator: PathGenerator

    init(fileManager: FileManager = .default, configuration: BlogConfiguration) {
        self.fileManager = fileManager
        self.configuration = configuration
        self.pathGenerator = PathGenerator(configuration: configuration.outputOptions)
    }
    
    func generate(_ source: Source) throws -> FilePath {
        let blogRoot = FilePath(configuration.outputOptions.directory)
        
        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: blogRoot.string, withIntermediateDirectories: true)
        
        // Load templates
        let templates = try loadTemplates(source: source)
        
        // Generate individual article pages
        for article in source.pages {
            try generateArticlePage(
                article: article,
                layoutTemplate: templates.layout,
                articleTemplate: templates.article,
                siteRoot: blogRoot
            )
        }
        
        // Generate list page (index.html)
        try generateListPage(
            pages: source.pages,
            layoutTemplate: templates.layout,
            listTemplate: templates.list,
            siteRoot: blogRoot
        )
        
        return blogRoot
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
        
        guard let articleData = fileManager.contents(atPath: configuration.templates.articleFile),
              let articleTemplate = String(data: articleData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(configuration.templates.articleFile)
        }
        
        guard let listData = fileManager.contents(atPath: configuration.templates.listFile),
              let listTemplate = String(data: listData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(configuration.templates.listFile)
        }
        
        return Templates(
            layout: layoutTemplate,
            article: articleTemplate,
            list: listTemplate
        )
    }
    
    private func generateArticlePage(
        article: Article,
        layoutTemplate: String,
        articleTemplate: String,
        siteRoot: FilePath
    ) throws {
        // Prepare data for article template
        let articleData: [String: Any] = [
            "title": article.title,
            "author": article.author,
            "publishedAt": formatDate(article.publishedAt),
            "body": article.htmlContent
        ]
        
        // Render article template
        let articleMustacheTemplate = try MustacheTemplate(string: articleTemplate)
        let renderedArticle = articleMustacheTemplate.render(articleData)
        
        // Prepare data for layout template
        let layoutData: [String: Any] = [
            "title": article.title,
            "blog_title": configuration.metadata.blogTitle,
            "home_url": pathGenerator.generateHomeURL(from: article.path),
            "content": renderedArticle
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write to file
        let fileName = pathGenerator.generateOutputPath(for: article.path)
        let outputPath = siteRoot.appending(fileName)
        
        // Create subdirectory if needed (for subdirectory style)
        let outputDirectory = outputPath.removingLastComponent()
        if outputDirectory != siteRoot {
            try fileManager.createDirectory(atPath: outputDirectory.string, withIntermediateDirectories: true)
        }
        
        try finalHTML.write(to: URL(fileURLWithPath: outputPath.string), atomically: true, encoding: .utf8)
    }
    
    private func generateListPage(
        pages: [Article],
        layoutTemplate: String,
        listTemplate: String,
        siteRoot: FilePath
    ) throws {
        // Prepare articles data for list template
        let articlesData = pages.map { article -> [String: Any] in
            let articleURL = pathGenerator.generateURL(for: article.path)
            
            return [
                "title": article.title,
                "author": article.author,
                "publishedAt": formatDate(article.publishedAt),
                "url": articleURL,
                "excerpt": article.excerpt,
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
            "blog_title": configuration.metadata.blogTitle,
            "home_url": pathGenerator.generateHomeURL(),
            "content": renderedList
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write index.html
        let indexPath = siteRoot.appending(configuration.outputOptions.indexFileName)
        try finalHTML.write(to: URL(fileURLWithPath: indexPath.string), atomically: true, encoding: .utf8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
