import Foundation
import Mustache

/// Handles template processing and site generation
struct BlogGenerator {
    private let fileManager: FileManager
    private let configuration: BlogConfiguration
    private let pathGenerator: PathGenerator
    private let formatter: DateFormatter

    init(fileManager: FileManager = .default, configuration: BlogConfiguration) throws {
        self.fileManager = fileManager
        self.configuration = configuration
        pathGenerator = PathGenerator(
            configuration: configuration.output,
            contentsBasePath: configuration.sourceLayout.contents,
            unlistedBasePath: configuration.sourceLayout.unlisted
        )
        formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = configuration.metadata.locale
    }

    func generate(_ source: Source) throws -> FilePath {
        let blogRoot = FilePath(configuration.output.directory)
        let pageRenderer = PageRenderer(templates: source.templates)

        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: blogRoot.string, withIntermediateDirectories: true)

        // Copy assets directory if it exists
        try copyAssetsIfExists(to: blogRoot)

        // Filter out unlisted posts for list pages
        let listedPosts = source.posts.filter { !$0.isUnlisted }

        // Extract years once and reuse (only from listed posts)
        let availableYears = try generateYearlyListPages(pageRenderer: pageRenderer, posts: listedPosts, blogRoot: blogRoot)

        // Generate individual post pages for ALL posts (including unlisted)
        for post in source.posts {
            try generatePostPage(pageRenderer: pageRenderer, post: post, years: availableYears, blogRoot: blogRoot)
        }

        // Generate list page (index.html) with only listed posts
        try generateListPage(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, blogRoot: blogRoot)

        return blogRoot
    }

    private func generatePostPage(pageRenderer: PageRenderer, post: Post, years: [String], blogRoot: FilePath) throws {
        // Prepare data for post template
        let postData = PostData(
            title: post.title,
            author: post.author,
            publishedAt: formatter.string(from: post.publishedAt),
            body: post.htmlContent,
        )

        // Prepare data for layout template
        let layoutData = LayoutData(
            pageTitle: "\(post.title) | \(configuration.metadata.blogName)",
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(from: post.path, isUnlisted: post.isUnlisted),
            assetsUrl: pathGenerator.generateAssetsUrl(from: post.path, isUnlisted: post.isUnlisted),
            years: years,
            content: postData,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write to file
        let fileName = pathGenerator.generateOutputPath(for: post.path, isUnlisted: post.isUnlisted)
        let outputPath = blogRoot.appending(fileName)

        // Create subdirectory if needed (for subdirectory style)
        let outputDirectory = outputPath.removingLastComponent()
        if outputDirectory != blogRoot {
            try fileManager.createDirectory(atPath: outputDirectory.string, withIntermediateDirectories: true)
        }

        fileManager.createFile(atPath: outputPath.string, contents: Data(finalHTML.utf8))
    }

    private func generateListPage(pageRenderer: PageRenderer, posts: [Post], years: [String], blogRoot: FilePath) throws {
        // Prepare posts data for list template
        let list = ListData(
            title: "Recent Posts",
            posts: posts.map { post in
                ListItemData(
                    title: post.title,
                    author: post.author,
                    publishedAt: formatter.string(from: post.publishedAt),
                    excerpt: post.excerpt,
                    url: pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted),
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
            years: years,
            content: list,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write index.html
        let indexPath = blogRoot.appending(configuration.output.indexFileName)
        fileManager.createFile(atPath: indexPath.string, contents: Data(finalHTML.utf8))
    }

    private func generateYearlyListPages(pageRenderer: PageRenderer, posts: [Post], blogRoot: FilePath) throws -> [String] {
        // Group posts by publication year
        let calendar = Calendar.current
        let postsByYear = Dictionary(grouping: posts) { post in
            calendar.component(.year, from: post.publishedAt)
        }

        // Extract and sort years for reuse
        let availableYears = postsByYear.keys.sorted(by: >).map { String($0) }

        // Generate a list page for each year that has posts
        for (year, yearPosts) in postsByYear {
            let yearPostsSorted = yearPosts.sorted { $0.publishedAt != $1.publishedAt ? $0.publishedAt > $1.publishedAt : $0.title > $1.title }

            // Prepare posts data for list template
            let list = ListData(
                title: String(describing: year),
                posts: yearPostsSorted.map { post in
                    ListItemData(
                        title: post.title,
                        author: post.author,
                        publishedAt: formatter.string(from: post.publishedAt),
                        excerpt: post.excerpt,
                        url: "../\(pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted))",
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
                years: availableYears,
                content: list,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)

            // Create year directory and write index.html
            let yearDirectory = blogRoot.appending("\(year)")
            try fileManager.createDirectory(atPath: yearDirectory.string, withIntermediateDirectories: true)

            let yearIndexPath = yearDirectory.appending(configuration.output.indexFileName)
            fileManager.createFile(atPath: yearIndexPath.string, contents: Data(finalHTML.utf8))
        }

        return availableYears
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
