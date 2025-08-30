import Foundation
import Mustache

/// Handles template processing and site generation
struct BlogGenerator {
    private let configuration: BlogConfiguration
    private let fileManager: FileManager
    private let buildVersion: String
    private let calendar: Calendar
    private let dateProvider: () -> Date
    private let pathGenerator: PathGenerator
    private let dateFormatter: DateFormatter

    init(
        configuration: BlogConfiguration,
        fileManager: FileManager = .default,
        calendar: Calendar = .current,
        dateProvider: @escaping () -> Date = { let now = Date(); return { now } }(),
    ) throws {
        self.configuration = configuration
        self.fileManager = fileManager
        self.calendar = calendar
        self.dateProvider = dateProvider
        pathGenerator = PathGenerator(
            configuration: configuration.output,
            contentsBasePath: configuration.sourceLayout.contents,
            unlistedBasePath: configuration.sourceLayout.unlisted
        )
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.locale = configuration.metadata.locale
        self.dateFormatter = dateFormatter
        self.buildVersion = String(dateProvider().timeIntervalSince1970)
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

        // Use precomputed years and categories from source
        let availableYears = source.years
        let availableCategories = source.categories

        // Generate yearly list pages (only from listed posts)
        try generateYearlyListPages(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)

        // Generate directory list pages (only from listed posts)
        try generateDirectoryListPages(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)

        // Generate individual post pages for ALL posts (including unlisted)
        for post in source.posts {
            try generatePostPage(pageRenderer: pageRenderer, post: post, years: availableYears, categories: availableCategories, blogRoot: blogRoot)
        }

        // Generate list page (index.html) with only listed posts
        try generateListPage(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)

        return blogRoot
    }

    private func generatePostPage(pageRenderer: PageRenderer, post: Post, years: [String], categories: [String], blogRoot: FilePath) throws {
        // Prepare data for post template
        let postData = PostData(
            title: post.title,
            author: post.author,
            publishedAt: dateFormatter.string(from: post.publishedAt),
            body: post.htmlContent,
        )

        // Prepare data for layout template
        let layoutData = LayoutData(
            content: postData,
            pageTitle: "\(post.title) | \(configuration.metadata.blogName)",
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(from: post.path, isUnlisted: post.isUnlisted),
            assetsUrl: pathGenerator.generateAssetsUrl(from: post.path, isUnlisted: post.isUnlisted),
            currentYear: getCurrentYear(),
            years: years,
            categories: categories,
            buildVersion: buildVersion,
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

    private func generateListPage(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws {
        // Prepare posts data for list template
        let list = ListData(
            title: nil, // Let users name title in layout.mustache
            posts: posts.map { post in
                ListItemData(
                    title: post.title,
                    author: post.author,
                    publishedAt: dateFormatter.string(from: post.publishedAt),
                    excerpt: post.excerpt,
                    url: pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted),
                )
            }
        )

        // Prepare data for layout template
        let layoutData = LayoutData(
            content: list,
            pageTitle: configuration.metadata.blogName,
            blogName: configuration.metadata.blogName,
            copyright: configuration.metadata.copyright,
            homeUrl: pathGenerator.generateHomeUrl(),
            assetsUrl: pathGenerator.generateAssetsUrl(),
            currentYear: getCurrentYear(),
            years: years,
            categories: categories,
            buildVersion: buildVersion,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write index.html
        let indexPath = blogRoot.appending(configuration.output.indexFileName)
        fileManager.createFile(atPath: indexPath.string, contents: Data(finalHTML.utf8))
    }

    private func generateYearlyListPages(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws {
        // Group posts by publication year
        let calendar = Calendar.current
        let postsByYear = Dictionary(grouping: posts) { post in
            calendar.component(.year, from: post.publishedAt)
        }

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
                        publishedAt: dateFormatter.string(from: post.publishedAt),
                        excerpt: post.excerpt,
                        url: "../\(pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted))",
                    )
                }
            )

            // Prepare data for layout template
            let layoutData = LayoutData(
                content: list,
                pageTitle: "\(year) - \(configuration.metadata.blogName)",
                blogName: configuration.metadata.blogName,
                copyright: configuration.metadata.copyright,
                homeUrl: "../",
                assetsUrl: "../assets/",
                currentYear: getCurrentYear(),
                years: years,
                categories: categories,
                buildVersion: buildVersion,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)

            // Create year directory and write index.html
            let yearDirectory = blogRoot.appending("\(year)")
            try fileManager.createDirectory(atPath: yearDirectory.string, withIntermediateDirectories: true)

            let yearIndexPath = yearDirectory.appending(configuration.output.indexFileName)
            fileManager.createFile(atPath: yearIndexPath.string, contents: Data(finalHTML.utf8))
        }
    }

    private func generateDirectoryListPages(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws {
        // Group posts by their top-level directory
        var directoryPosts: [String: [Post]] = [:]

        for post in posts where !post.isUnlisted {
            // Get the relative path within the contents directory
            let contentsPath = configuration.sourceLayout.contents.string
            let postPath = post.path.string

            // Remove the contents base path to get the relative path
            guard postPath.hasPrefix(contentsPath) else { continue }
            let relativePath = String(postPath.dropFirst(contentsPath.count + 1)) // +1 for the trailing slash
            let pathComponents = relativePath.split(separator: "/")

            // Skip posts directly in contents root (no directory)
            guard pathComponents.count > 1 else { continue }

            let topLevelDirectory = String(pathComponents[0])

            // Skip imported directory (based on configuration)
            let importedDirName = configuration.sourceLayout.imported.lastComponent?.string ?? "imported"
            if topLevelDirectory == importedDirName {
                continue
            }

            if directoryPosts[topLevelDirectory] == nil {
                directoryPosts[topLevelDirectory] = []
            }
            directoryPosts[topLevelDirectory]?.append(post)
        }

        // Generate a list page for each directory that has posts
        for (directory, dirPosts) in directoryPosts {
            let dirPostsSorted = dirPosts.sorted {
                $0.publishedAt != $1.publishedAt ? $0.publishedAt > $1.publishedAt : $0.title > $1.title
            }

            // Prepare posts data for list template
            let list = ListData(
                title: directory.capitalized,
                posts: dirPostsSorted.map { post in
                    ListItemData(
                        title: post.title,
                        author: post.author,
                        publishedAt: dateFormatter.string(from: post.publishedAt),
                        excerpt: post.excerpt,
                        url: "../\(pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted))",
                    )
                }
            )

            // Prepare data for layout template
            let layoutData = LayoutData(
                content: list,
                pageTitle: "\(directory.capitalized) - \(configuration.metadata.blogName)",
                blogName: configuration.metadata.blogName,
                copyright: configuration.metadata.copyright,
                homeUrl: "../",
                assetsUrl: "../assets/",
                currentYear: getCurrentYear(),
                years: years,
                categories: categories,
                buildVersion: buildVersion,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)

            // Create directory and write index.html
            let directoryPath = blogRoot.appending(directory)
            try fileManager.createDirectory(atPath: directoryPath.string, withIntermediateDirectories: true)

            let dirIndexPath = directoryPath.appending(configuration.output.indexFileName)
            fileManager.createFile(atPath: dirIndexPath.string, contents: Data(finalHTML.utf8))
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

    private func getCurrentYear() -> String {
        String(describing: calendar.dateComponents([.year], from: dateProvider()).year!)
    }
}
