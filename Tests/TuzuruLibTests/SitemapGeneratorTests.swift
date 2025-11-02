import Foundation
import Testing
import Mustache
@testable import TuzuruLib

@Suite
struct SitemapGeneratorTests {

    // MARK: - Test Fixtures

    func makePathGenerator() -> PathGenerator {
        let outputConfig = BlogOutputOptions(
            directory: "blog",
            routingStyle: .direct,
            homePageStyle: .all
        )
        return PathGenerator(
            configuration: outputConfig,
            contentsBasePath: FilePath("/blog/contents"),
            unlistedBasePath: FilePath("/blog/contents/unlisted")
        )
    }

    func makeTestPost(
        path: String = "/blog/contents/test-post.md",
        title: String = "Test Post",
        isUnlisted: Bool = false
    ) -> Post {
        Post(
            path: FilePath(path),
            title: title,
            author: "Test Author",
            publishedAt: Date(timeIntervalSince1970: 1609459200), // 2021-01-01
            excerpt: "Test excerpt",
            content: "Test content",
            htmlContent: "<p>Test content</p>",
            isUnlisted: isUnlisted
        )
    }

    func makeTestSource(posts: [Post], years: [String] = [], categories: [String] = []) throws -> Source {
        // Create empty templates for testing
        var templates = MustacheLibrary()
        try templates.register("", named: "layout")
        try templates.register("", named: "list")
        try templates.register("", named: "post")

        return Source(
            metadata: BlogMetadata(
                blogName: "Test Blog",
                copyright: "© 2024",
                description: "Test",
                baseUrl: "https://example.com",
                locale: Locale(identifier: "en_US")
            ),
            templates: templates,
            posts: posts,
            years: years,
            categories: categories
        )
    }

    // MARK: - generateSitemap Tests

    @Test("Generate sitemap with single post")
    func generateSitemapWithSinglePost() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let post = makeTestPost()
        let source = try makeTestSource(posts: [post])

        let sitemap = try generator.generateSitemap(from: source)

        // Verify XML structure
        #expect(sitemap.contains("<?xml"))
        #expect(sitemap.contains("<urlset"))
        #expect(sitemap.contains("http://www.sitemaps.org/schemas/sitemap/0.9"))
        #expect(sitemap.contains("</urlset>"))
    }

    @Test("Sitemap includes home page URL")
    func sitemapIncludesHomePageUrl() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let source = try makeTestSource(posts: [])

        let sitemap = try generator.generateSitemap(from: source)

        #expect(sitemap.contains("<loc>https://example.com/</loc>"))
        #expect(sitemap.contains("<priority>1.0</priority>"))
    }

    @Test("Sitemap includes post URL with correct priority")
    func sitemapIncludesPostUrl() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let post = makeTestPost(path: "/blog/contents/my-post.md", title: "My Post")
        let source = try makeTestSource(posts: [post])

        let sitemap = try generator.generateSitemap(from: source)

        #expect(sitemap.contains("https://example.com/my-post.html"))
        #expect(sitemap.contains("<priority>0.8</priority>")) // Listed post priority
    }

    @Test("Sitemap includes unlisted post with lower priority")
    func sitemapIncludesUnlistedPost() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let unlistedPost = makeTestPost(
            path: "/blog/contents/unlisted/secret.md",
            isUnlisted: true
        )
        let source = try makeTestSource(posts: [unlistedPost])

        let sitemap = try generator.generateSitemap(from: source)

        #expect(sitemap.contains("secret.html"))
        #expect(sitemap.contains("<priority>0.5</priority>")) // Unlisted post priority
    }

    @Test("Sitemap includes year URLs when posts exist")
    func sitemapIncludesYearUrls() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let post = makeTestPost()
        let source = try makeTestSource(posts: [post], years: ["2021", "2022"])

        let sitemap = try generator.generateSitemap(from: source)

        #expect(sitemap.contains("https://example.com/2021/"))
        #expect(sitemap.contains("https://example.com/2022/"))
    }

    @Test("Sitemap sorts posts by date descending")
    func sitemapSortsPostsByDate() throws {
        let pathGenerator = makePathGenerator()
        let fileManager = FileManagerWrapper(workingDirectory: "/tmp")
        let generator = SitemapGenerator(
            pathGenerator: pathGenerator,
            baseUrl: "https://example.com",
            fileManager: fileManager
        )

        let olderPost = Post(
            path: FilePath("/blog/contents/old.md"),
            title: "Old Post",
            author: "Author",
            publishedAt: Date(timeIntervalSince1970: 1609459200), // 2021-01-01
            excerpt: "Old",
            content: "Old content",
            htmlContent: "<p>Old</p>",
            isUnlisted: false
        )

        let newerPost = Post(
            path: FilePath("/blog/contents/new.md"),
            title: "New Post",
            author: "Author",
            publishedAt: Date(timeIntervalSince1970: 1640995200), // 2022-01-01
            excerpt: "New",
            content: "New content",
            htmlContent: "<p>New</p>",
            isUnlisted: false
        )

        let source = try makeTestSource(posts: [olderPost, newerPost])
        let sitemap = try generator.generateSitemap(from: source)

        // Newer post should appear before older post in XML
        let newIndex = sitemap.range(of: "new.html")?.lowerBound
        let oldIndex = sitemap.range(of: "old.html")?.lowerBound

        #expect(newIndex != nil)
        #expect(oldIndex != nil)
        #expect(newIndex! < oldIndex!)
    }
}
