import Foundation
import Mustache

/// Handles template processing and site generation
struct BlogGenerator {
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper
    private let buildVersion: String
    private let calendar: Calendar
    private let dateProvider: () -> Date
    private let pathGenerator: PathGenerator
    private let dateFormatter: DateFormatter

    init(
        configuration: BlogConfiguration,
        fileManager: FileManagerWrapper,
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
        
        // Initialize integrity manager
        let integrityManager = IntegrityManager(fileManager: fileManager, blogConfiguration: configuration)
        
        // Load existing manifest and check if cleanup is needed
        let existingManifest = try integrityManager.loadExistingManifest()
        let cleanupNeeded = try integrityManager.isCleanupNeeded()

        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: blogRoot, withIntermediateDirectories: true)

        // Copy assets directory if it exists
        try copyAssetsIfExists(to: blogRoot)

        // Filter out unlisted posts for list pages
        let listedPosts = source.posts.filter { !$0.isUnlisted }

        // Use precomputed years and categories from source
        let availableYears = source.years
        let availableCategories = source.categories

        // Track all generated files for manifest
        var generatedFiles: [FilePath] = []
        
        // Generate index page (first so we can track it)
        try generateListPage(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)
        generatedFiles.append(blogRoot.appending(configuration.output.indexFileName))

        // Generate yearly list pages (only from listed posts)
        let yearlyFiles = try generateYearlyListPages(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)
        generatedFiles.append(contentsOf: yearlyFiles)

        // Generate directory list pages (only from listed posts)
        let directoryFiles = try generateDirectoryListPages(pageRenderer: pageRenderer, posts: listedPosts, years: availableYears, categories: availableCategories, blogRoot: blogRoot)
        generatedFiles.append(contentsOf: directoryFiles)

        // Generate individual post pages for ALL posts (including unlisted)
        for post in source.posts {
            try generatePostPage(pageRenderer: pageRenderer, post: post, years: availableYears, categories: availableCategories, blogRoot: blogRoot)
            let outputPath = pathGenerator.generateOutputPath(for: post.path, isUnlisted: post.isUnlisted)
            generatedFiles.append(blogRoot.appending(outputPath))
        }
        
        // Generate sitemap.xml
        let sitemapGenerator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: configuration.metadata.baseUrl,
            fileManager: fileManager
        )
        try sitemapGenerator.generateAndSave(from: source, to: blogRoot)
        generatedFiles.append(blogRoot.appending("sitemap.xml"))
        
        // Perform integrity cleanup if needed
        if cleanupNeeded, let manifest = existingManifest {
            try integrityManager.performCleanup(with: manifest, newGeneratedFiles: generatedFiles)
        }
        
        // Save new manifest
        try integrityManager.saveNewManifest(generatedFiles: generatedFiles)

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
            description: configuration.metadata.description,
            homeUrl: pathGenerator.generateHomeUrl(from: post.path, isUnlisted: post.isUnlisted),
            currentPageUrl: pathGenerator.generateAbsoluteUrl(baseUrl: configuration.metadata.baseUrl, relativePath: pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted)),
            assetsUrl: pathGenerator.generateAssetsUrl(from: post.path, isUnlisted: post.isUnlisted),
            currentYear: getCurrentYear(),
            hasYears: !years.isEmpty,
            years: years,
            hasCategories: !categories.isEmpty,
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
            try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
        }

        _ = fileManager.createFile(atPath: outputPath, contents: Data(finalHTML.utf8))
    }

    private func generateListPage(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws {
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: dateProvider())!
        let filteredPosts = switch configuration.output.homePageStyle {
        case .all:
            posts
        case .pastYear:
            posts.filter {
                oneYearAgo < $0.publishedAt &&
                // If a file is not commited yet, publishedAt and dateProvider()'s now will be the almost same
                // but `dateProvider`'s time is fixed when BlogGenerator is initialized and a new post's publishedAt is later.
                // Add 10 seconds allow us to bring the draft page for `serve`'s preview whilst guarding displaying future pages.
                $0.publishedAt <= dateProvider().addingTimeInterval(10)
            }
        case .last(let number):
            Array(posts.prefix(number))
        }
        let sortedPosts = filteredPosts.sorted { $0.publishedAt != $1.publishedAt ? $0.publishedAt > $1.publishedAt : $0.title > $1.title }

        // Prepare posts data for list template
        let list = ListData(
            title: nil, // Let users name title in layout.mustache
            posts: sortedPosts.map { post in
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
            description: configuration.metadata.description,
            homeUrl: pathGenerator.generateHomeUrl(),
            currentPageUrl: pathGenerator.generateAbsoluteUrl(baseUrl: configuration.metadata.baseUrl, relativePath: ""),
            assetsUrl: pathGenerator.generateAssetsUrl(),
            currentYear: getCurrentYear(),
            hasYears: !years.isEmpty,
            years: years,
            hasCategories: !categories.isEmpty,
            categories: categories,
            buildVersion: buildVersion,
        )

        // Render final page
        let finalHTML = try pageRenderer.render(layoutData)

        // Write index.html
        let indexPath = blogRoot.appending(configuration.output.indexFileName)
        _ = fileManager.createFile(atPath: indexPath, contents: Data(finalHTML.utf8))
    }

    private func generateYearlyListPages(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws -> [FilePath] {
        // Group posts by publication year
        let calendar = Calendar.current
        let postsByYear = Dictionary(grouping: posts) { post in
            calendar.component(.year, from: post.publishedAt)
        }
        
        var generatedFiles: [FilePath] = []

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
                description: configuration.metadata.description,
                homeUrl: "../",
                currentPageUrl: pathGenerator.generateAbsoluteUrl(baseUrl: configuration.metadata.baseUrl, relativePath: "\(year)/"),
                assetsUrl: "../assets/",
                currentYear: getCurrentYear(),
                hasYears: !years.isEmpty,
                years: years,
                hasCategories: !categories.isEmpty,
                categories: categories,
                buildVersion: buildVersion,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)

            // Create year directory and write index.html
            let yearDirectory = blogRoot.appending("\(year)")
            try fileManager.createDirectory(atPath: yearDirectory, withIntermediateDirectories: true)

            let yearIndexPath = yearDirectory.appending(configuration.output.indexFileName)
            _ = fileManager.createFile(atPath: yearIndexPath, contents: Data(finalHTML.utf8))
            generatedFiles.append(yearIndexPath)
        }
        
        return generatedFiles
    }

    private func generateDirectoryListPages(pageRenderer: PageRenderer, posts: [Post], years: [String], categories: [String], blogRoot: FilePath) throws -> [FilePath] {
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

        var generatedFiles: [FilePath] = []

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
                description: configuration.metadata.description,
                homeUrl: "../",
                currentPageUrl: pathGenerator.generateAbsoluteUrl(baseUrl: configuration.metadata.baseUrl, relativePath: "\(directory)/"),
                assetsUrl: "../assets/",
                currentYear: getCurrentYear(),
                hasYears: !years.isEmpty,
                years: years,
                hasCategories: !categories.isEmpty,
                categories: categories,
                buildVersion: buildVersion,
            )

            // Render final page
            let finalHTML = try pageRenderer.render(layoutData)

            // Create directory and write index.html
            let directoryPath = blogRoot.appending(directory)
            try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)

            let dirIndexPath = directoryPath.appending(configuration.output.indexFileName)
            _ = fileManager.createFile(atPath: dirIndexPath, contents: Data(finalHTML.utf8))
            generatedFiles.append(dirIndexPath)
        }
        
        return generatedFiles
    }

    private func copyAssetsIfExists(to blogRoot: FilePath) throws {
        let assetsPath = configuration.sourceLayout.assets

        // Check if assets directory exists
        guard fileManager.fileExists(atPath: assetsPath) else {
            return // No assets directory, nothing to copy
        }

        let destinationPath = blogRoot.appending("assets")

        // Remove existing assets directory if it exists
        if fileManager.fileExists(atPath: destinationPath) {
            try fileManager.removeItem(atPath: destinationPath)
        }

        // Copy the entire assets directory
        try fileManager.copyItem(atPath: assetsPath, toPath: destinationPath)
    }

    private func getCurrentYear() -> String {
        String(describing: calendar.component(.year, from: dateProvider()))
    }
}
