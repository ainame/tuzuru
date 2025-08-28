import Foundation
import Mustache
import System

/// Handles template processing and site generation
struct BlogGenerator {
    private let fileManager: FileManager
    private let configuration: BlogConfiguration
    private let pathGenerator: PathGenerator
    private let formatter: DateFormatter

    init(fileManager: FileManager = .default, configuration: BlogConfiguration) throws {
        self.fileManager = fileManager
        self.configuration = configuration
        pathGenerator = PathGenerator(configuration: configuration.outputOptions, contentsBasePath: configuration.sourceLayout.contents)
        formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = configuration.metadata.locale
    }

    func generate(_ source: Source) throws -> FilePath {
        let blogRoot = FilePath(configuration.outputOptions.directory)
        let pageRenderer = PageRenderer(templates: source.templates)

        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: blogRoot.string, withIntermediateDirectories: true)

        // Copy assets directory if it exists
        try copyAssetsIfExists(to: blogRoot)

        // Generate individual article pages
        for article in source.articles {
            try generateArticlePage(pageRenderer: pageRenderer, article: article, blogRoot: blogRoot)
        }

        // Generate list page (index.html)
        try generateListPage(pageRenderer: pageRenderer, articles: source.articles, blogRoot: blogRoot)
        
        // Generate yearly list pages
        try generateYearlyListPages(pageRenderer: pageRenderer, articles: source.articles, blogRoot: blogRoot)

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

        // Prepare data for layout template
        let layoutData = LayoutData(
            pageTitle: "\(article.title) | \(configuration.metadata.blogName)",
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(from: article.path),
            assetsUrl: pathGenerator.generateAssetsUrl(from: article.path),
            content: articleData,
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
        let list = ListData(
            title: "Recent Posts",
            articles: articles.map { article in
                ListItemData(
                    title: article.title,
                    author: article.author,
                    publishedAt: formatter.string(from: article.publishedAt),
                    excerpt: article.excerpt,
                    url: pathGenerator.generateUrl(for: article.path),
                )
            }
        )

        // Prepare data for layout template
        let layoutData = LayoutData(
            pageTitle: configuration.metadata.blogName,
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(),
            assetsUrl: pathGenerator.generateAssetsUrl(),
            content: list,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write index.html
        let indexPath = blogRoot.appending(configuration.outputOptions.indexFileName)
        fileManager.createFile(atPath: indexPath.string, contents: Data(finalHTML.utf8))
    }
    
    private func generateYearlyListPages(pageRenderer: PageRenderer, articles: [Article], blogRoot: FilePath) throws {
        // Group articles by publication year
        let calendar = Calendar.current
        let articlesByYear = Dictionary(grouping: articles) { article in
            calendar.component(.year, from: article.publishedAt)
        }
        
        // Generate a list page for each year that has articles
        for (year, yearArticles) in articlesByYear {
            let yearArticlesSorted = yearArticles.sorted { $0.publishedAt > $1.publishedAt }
            
            // Prepare articles data for list template
            let list = ListData(
                title: String(describing: year),
                articles: yearArticlesSorted.map { article in
                    ListItemData(
                        title: article.title,
                        author: article.author,
                        publishedAt: formatter.string(from: article.publishedAt),
                        excerpt: article.excerpt,
                        url: "../\(pathGenerator.generateUrl(for: article.path))",
                    )
                }
            )

            // Prepare data for layout template
            let layoutData = LayoutData(
                pageTitle: "\(year) - \(configuration.metadata.blogName)",
                blogName: configuration.metadata.blogName,
                copyright: configuration.metadata.copyright,
                homeUrl: "../",
                assetsUrl: "../assets/",
                content: list,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)
            
            // Create year directory and write index.html
            let yearDirectory = blogRoot.appending("\(year)")
            try fileManager.createDirectory(atPath: yearDirectory.string, withIntermediateDirectories: true)
            
            let yearIndexPath = yearDirectory.appending(configuration.outputOptions.indexFileName)
            fileManager.createFile(atPath: yearIndexPath.string, contents: Data(finalHTML.utf8))
        }
    }

    private func copyAssetsIfExists(to blogRoot: FilePath) throws {
        let assetsPath = configuration.sourceLayout.assets
        
        // Check if assets directory exists
        guard fileManager.fileExists(atPath: assetsPath.string) else {
            return // No assets directory, nothing to copy
        }
        
        let destinationPath = blogRoot.appending("assets")
        
        // Remove existing assets directory if it exists
        if fileManager.fileExists(atPath: destinationPath.string) {
            try fileManager.removeItem(atPath: destinationPath.string)
        }
        
        // Copy the entire assets directory
        try fileManager.copyItem(atPath: assetsPath.string, toPath: destinationPath.string)
    }
}
