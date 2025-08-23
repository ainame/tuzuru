import Foundation
import Mustache
import System

/// Handles template processing and site generation
struct BlogGenerator {
    private let fileManager: FileManager
    private let configuration: BlogConfiguration
    private let pathGenerator: PathGenerator
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    init(fileManager: FileManager = .default, configuration: BlogConfiguration) throws {
        self.fileManager = fileManager
        self.configuration = configuration
        pathGenerator = PathGenerator(configuration: configuration.outputOptions)
    }

    func generate(_ source: Source) throws -> FilePath {
        let blogRoot = FilePath(configuration.outputOptions.directory)
        let pageRenderer = PageRenderer(templates: source.templates)

        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: blogRoot.string, withIntermediateDirectories: true)

        // Generate individual article pages
        for article in source.articles {
            try generateArticlePage(pageRenderer: pageRenderer, article: article, blogRoot: blogRoot)
        }

        // Generate list page (index.html)
        try generateListPage(pageRenderer: pageRenderer, articles: source.articles, blogRoot: blogRoot)

        return blogRoot
    }

    private func generateArticlePage(pageRenderer: PageRenderer, article: Article, blogRoot: FilePath) throws {
        // Prepare data for article template
        let articleData = ArticleData(
            title: article.title,
            author: article.author,
            publishedAt: formatter.string(from: article.publishedAt),
            body: article.htmlContent,
        )

        let renderedArticle = try pageRenderer.render(articleData)

        // Prepare data for layout template
        let layoutData = LayoutData(
            pageTitle: "\(article.title) | \(configuration.metadata.blogName)",
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(from: article.path),
            content: renderedArticle,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write to file
        let fileName = pathGenerator.generateOutputPath(for: article.path)
        let outputPath = blogRoot.appending(fileName)

        // Create subdirectory if needed (for subdirectory style)
        let outputDirectory = outputPath.removingLastComponent()
        if outputDirectory != blogRoot {
            try fileManager.createDirectory(atPath: outputDirectory.string, withIntermediateDirectories: true)
        }

        fileManager.createFile(atPath: outputPath.string, contents: Data(finalHTML.utf8))
    }

    private func generateListPage(pageRenderer: PageRenderer, articles: [Article], blogRoot: FilePath) throws {
        // Prepare articles data for list template
        let listItems = articles.map { article in
            ListItemData(
                title: article.title,
                author: article.author,
                publishedAt: formatter.string(from: article.publishedAt),
                excerpt: article.excerpt,
                url: pathGenerator.generateUrl(for: article.path),
            )
        }

        // Render list template
        let renderedList = try pageRenderer.render(listItems)

        // Prepare data for layout template
        let layoutData = LayoutData(
            pageTitle: configuration.metadata.blogName,
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(),
            content: renderedList,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write index.html
        let indexPath = blogRoot.appending(configuration.outputOptions.indexFileName)
        fileManager.createFile(atPath: indexPath.string, contents: Data(finalHTML.utf8))
    }
}
