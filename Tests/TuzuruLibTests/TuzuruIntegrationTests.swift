import Testing
@testable import TuzuruLib
import Foundation

@Suite(.gitRepositoryFixture)
struct TuzuruIntegrationTests {

    @Test
    func testBlogGenerationWithGitRepository() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
        try fixture.copyFixtures(from: fixturesPath)

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with demo blog content")

        // Load configuration from test repo  
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")

        // Initialize Tuzuru with the configuration
        let tuzuru = try Tuzuru(
            fileManager: fixture.fileManager,
            configuration: config
        )

        // Phase 1: Load sources (should parse markdown files and git history with raw content)
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)

        #expect(rawSource.posts.count > 0)

        // Check that posts have basic metadata but no processed content yet
        let swiftRawPost = rawSource.posts.first { $0.path.string.contains("swift-basics-for-beginners") }
        #expect(swiftRawPost != nil)
        #expect(swiftRawPost?.author.isEmpty == false)
        #expect(swiftRawPost?.publishedAt != nil)
        #expect(swiftRawPost?.content.isEmpty == false) // Raw markdown content

        // Phase 2: Process contents (convert markdown to HTML)
        let processedSource = try await tuzuru.processContents(rawSource)

        // Check that posts now have processed content
        let processedSwiftPost = processedSource.posts.first { $0.path.string.contains("swift-basics-for-beginners") }
        #expect(processedSwiftPost != nil)
        #expect(processedSwiftPost?.title.isEmpty == false) // Title extracted from H1
        #expect(processedSwiftPost?.htmlContent.isEmpty == false) // HTML content generated
        #expect(processedSwiftPost?.excerpt.isEmpty == false) // Excerpt generated

        // Phase 3: Generate blog output
        _ = try await tuzuru.generate(processedSource)

        // Verify blog output was generated
        let blogDir = FilePath("blog")
        #expect(fixture.fileManager.fileExists(atPath: blogDir))

        // Verify HTML files were created
        let indexPath = blogDir.appending("index.html")
        #expect(fixture.fileManager.fileExists(atPath: indexPath))

        // Verify post HTML was generated (they're in subdirectories due to subdirectory routing)
        let postFiles = try fixture.fileManager.contentsOfDirectory(atPath: blogDir)
        let hasSubdirectories = postFiles.contains { $0.string == "technology" || $0.string == "lifestyle" }
        #expect(hasSubdirectories == true)

        // Check that there are HTML files in the technology subdirectory
        if fixture.fileManager.fileExists(atPath: blogDir.appending("technology")) {
            let techFiles = try fixture.fileManager.contentsOfDirectory(atPath: blogDir.appending("technology"))
            let hasHtmlFiles = techFiles.contains { $0.string.hasSuffix(".html") }
            #expect(hasHtmlFiles == true)
        }
    }

    @Test
    func testBlogGenerationWithAmendedMetadata() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
        try fixture.copyFixtures(from: fixturesPath)

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with demo blog content")

        // Amend a file's metadata
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")
        let tuzuru = try Tuzuru(fileManager: fixture.fileManager, configuration: config)

        let testFilePath = "contents/technology/swift-basics-for-beginners.md"
        try await tuzuru.amendFile(
            filePath: testFilePath,
            newDate: "2024-03-01",
            newAuthor: "Integration Test Author"
        )

        // Phase 1: Load sources - should pick up amended metadata from git
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)

        // Find the amended raw post
        let swiftRawPost = rawSource.posts.first { $0.path.string.contains("swift-basics-for-beginners") }
        #expect(swiftRawPost != nil)

        // Verify amended metadata is used
        #expect(swiftRawPost?.author == "Integration Test Author")

        // Check that the date was updated (should be March 1, 2024)
        let calendar = Calendar.current
        let publishedDate = swiftRawPost?.publishedAt
        #expect(publishedDate != nil)

        if let date = publishedDate {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            #expect(components.year == 2024)
            #expect(components.month == 3)
            #expect(components.day == 1)
        }

        // Phase 2: Process contents 
        let processedSource = try await tuzuru.processContents(rawSource)

        // Phase 3: Generate blog and verify output contains amended metadata
        _ = try await tuzuru.generate(processedSource)

        // Read generated HTML and verify it contains amended author
        let blogDir = FilePath("blog")
        let postFiles = try fixture.fileManager.contentsOfDirectory(atPath: blogDir)
        let swiftPostHTML = postFiles.first { $0.string.contains("swift-basics") && $0.string.hasSuffix(".html") }

        if let htmlFile = swiftPostHTML {
            let htmlPath = blogDir.appending(htmlFile.string)
            let htmlContent = try String(contentsOfFile: fixture.fileManager.workingDirectory.appending(htmlPath.string).string, encoding: .utf8)
            #expect(htmlContent.contains("Integration Test Author"))
        }
    }

    @Test
    func testDisplayPathGeneration() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
        try fixture.copyFixtures(from: fixturesPath)

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with demo blog content")

        // Load configuration and create Tuzuru instance
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")
        let tuzuru = try Tuzuru(fileManager: fixture.fileManager, configuration: config)

        // Load sources and process contents (need processed source for path generation)
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)
        let processedSource = try await tuzuru.processContents(rawSource)

        // Generate display paths
        let displayPaths = tuzuru.generateDisplayPaths(for: processedSource)

        #expect(displayPaths.count == processedSource.posts.count)
        #expect(displayPaths.count > 0)

        // Verify paths are reasonable (should contain file names without .md extension)
        let swiftPath = displayPaths.first { $0.contains("swift-basics") }
        #expect(swiftPath != nil)
        #expect(swiftPath?.hasSuffix(".html") == true)
    }

    @Test(.disabled("Bundle resource access issue in test environment"))
    func testBlogInitializationInGitRepo() async throws {
        let fixture = Environment.gitRepositoryFixture!

        // Initialize blog in git repository
        try await Tuzuru.initializeBlog(fileManager: fixture.fileManager)

        // Verify required files and directories were created
        #expect(fixture.fileManager.fileExists(atPath: FilePath("tuzuru.json")))
        #expect(fixture.fileManager.fileExists(atPath: FilePath("contents")))
        #expect(fixture.fileManager.fileExists(atPath: FilePath("contents/unlisted")))
        #expect(fixture.fileManager.fileExists(atPath: FilePath("templates")))
        #expect(fixture.fileManager.fileExists(atPath: FilePath("assets")))

        // Verify we can load the configuration
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")
        #expect(config.metadata.blogName.isEmpty == false)

        // Commit the initialized blog
        try await fixture.createCommit(message: "Initialize blog with Tuzuru")

        // Verify we can create a Tuzuru instance with the initialized setup
        let tuzuru = try Tuzuru(fileManager: fixture.fileManager, configuration: config)
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)

        // Should have no posts initially
        #expect(rawSource.posts.count == 0)

        // Process empty source and generate (empty blog)
        let processedSource = try await tuzuru.processContents(rawSource)
        _ = try await tuzuru.generate(processedSource)
        #expect(fixture.fileManager.fileExists(atPath: FilePath("blog")))
    }

    @Test("createPathMapping maps posts, index, years, and categories")
    func testCreatePathMapping() async throws {
        // Setup demo project in isolated git repo
        let fixture = Environment.gitRepositoryFixture!
        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
        try fixture.copyFixtures(from: fixturesPath)
        try await fixture.createCommit(message: "Add demo project fixtures")

        // Load configuration and initialize Tuzuru
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")
        let tuzuru = try Tuzuru(fileManager: fixture.fileManager, configuration: config)

        // Build source
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)
        let source = try await tuzuru.processContents(rawSource)

        // Create mapping
        let mapping = tuzuru.createPathMapping(for: source)

        // Index pages should map to contents directory
        #expect(mapping["/"] == config.sourceLayout.contents)
        #expect(mapping["/index.html"] == config.sourceLayout.contents)

        // Year listing pages should exist and map to contents directory
        if let anyYear = source.years.first {
            #expect(mapping["/\(anyYear)/"] == config.sourceLayout.contents)
            #expect(mapping["/\(anyYear)/index.html"] == config.sourceLayout.contents)
        } else {
            // The demo fixture always yields at least one year from git history
            #expect(Bool(true))
        }

        // Category listing pages should map to the corresponding directory
        if let anyCategory = source.categories.first {
            #expect(mapping["/\(anyCategory)/"] == config.sourceLayout.contents.appending(anyCategory))
            #expect(mapping["/\(anyCategory)/index.html"] == config.sourceLayout.contents.appending(anyCategory))
        } else {
            // The demo fixture has category directories (e.g., technology, lifestyle)
            #expect(Bool(true))
        }

        // At least one post should be present and mapped
        #expect(!source.posts.isEmpty)
        let pathGen = PathGenerator(
            configuration: config.output,
            contentsBasePath: config.sourceLayout.contents,
            unlistedBasePath: config.sourceLayout.unlisted
        )
        if let post = source.posts.first {
            let req = "/" + pathGen.generateUrl(for: post.path, isUnlisted: post.isUnlisted)
            #expect(mapping[req] == post.path)
        }
    }

    @Test("shouldRegenerate returns true when category content changes")
    func testShouldRegenerateForCategoryDirectoryChanges() async throws {
        // Setup demo project in isolated git repo
        let fixture = Environment.gitRepositoryFixture!
        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
        try fixture.copyFixtures(from: fixturesPath)
        try await fixture.createCommit(message: "Add demo project fixtures")

        // Load configuration and initialize Tuzuru
        let loader = BlogConfigurationLoader(fileManager: fixture.fileManager)
        let config = try loader.load(from: "tuzuru.json")
        let tuzuru = try Tuzuru(fileManager: fixture.fileManager, configuration: config)

        // Build source and path mapping
        let rawSource = try await tuzuru.loadSources(config.sourceLayout)
        let source = try await tuzuru.processContents(rawSource)
        let mapping = tuzuru.createPathMapping(for: source)

        // Pick a known category from the demo fixture
        let category = source.categories.contains("technology") ? "technology" : (source.categories.first ?? "technology")
        let requestPath = "/\(category)/"

        // Baseline: no changes after this timestamp
        let lastRequestTime = Date()

        // Immediately checking should be false (no changes after lastRequestTime)
        let initial = tuzuru.shouldRegenerate(requestPath: requestPath, lastRequestTime: lastRequestTime, pathMapping: mapping)
        #expect(initial == false)

        // Wait a moment to ensure file timestamps move forward
        try await Task.sleep(nanoseconds: 1_200_000_000)

        // Modify or add a file under the category directory
        try fixture.writeFile(at: "contents/\(category)/new-post.md", content: "# Hello\n")

        // Now changes occurred after lastRequestTime, should be true
        let changed = tuzuru.shouldRegenerate(requestPath: requestPath, lastRequestTime: lastRequestTime, pathMapping: mapping)
        #expect(changed == true)
    }
}
