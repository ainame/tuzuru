//import Testing
//@testable import TuzuruLib
//import Foundation
//
//@Suite(.gitRepositoryFixture)
//struct TuzuruIntegrationTests {
//    
//    @Test
//    func testBlogGenerationWithGitRepository() async throws {
//        let fixture = GitRepositoryFixture.shared
//        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
//        try fixture.copyFixtures(from: fixturesPath)
//        
//        // Create initial commit
//        try fixture.createCommit(message: "Initial commit with demo blog content")
//        
//        // Change working directory to test repo for Tuzuru operations
//        let originalDir = fixture.setupWorkingDirectory()
//        defer { fixture.restoreWorkingDirectory(originalDir) }
//        
//        // Load configuration from test repo
//        let config = try Tuzuru.loadConfiguration(from: "tuzuru.json")
//        
//        // Initialize Tuzuru with the configuration
//        let tuzuru = try Tuzuru(
//            fileManager: FileManager.default,
//            configuration: config
//        )
//        
//        // Load sources (should parse markdown files and git history)
//        let source = try await tuzuru.loadSources(config.sourceLayout)
//        
//        #expect(source.posts.count > 0)
//        
//        // Check that posts have proper metadata (some may come from git)
//        let swiftPost = source.posts.first { $0.path.string.contains("swift-basics-for-beginners") }
//        #expect(swiftPost != nil)
//        #expect(swiftPost?.title.isEmpty == false)
//        #expect(swiftPost?.author.isEmpty == false)
//        #expect(swiftPost?.publishedAt != nil)
//        
//        // Generate blog output
//        let _ = try await tuzuru.generate(source)
//        
//        // Verify blog output was generated
//        let blogDir = fixture.tempPath.appending("blog")
//        #expect(FileManager.default.fileExists(atPath: blogDir.string))
//        
//        // Verify HTML files were created
//        let indexPath = blogDir.appending("index.html")
//        #expect(FileManager.default.fileExists(atPath: indexPath.string))
//        
//        // Verify post HTML was generated
//        let postFiles = try FileManager.default.contentsOfDirectory(atPath: blogDir.string)
//        let hasPostFiles = postFiles.contains { $0.hasSuffix(".html") && $0 != "index.html" }
//        #expect(hasPostFiles == true)
//    }
//    
//    @Test
//    func testBlogGenerationWithAmendedMetadata() async throws {
//        let fixture = GitRepositoryFixture.shared
//        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
//        try fixture.copyFixtures(from: fixturesPath)
//        
//        // Create initial commit
//        try fixture.createCommit(message: "Initial commit with demo blog content")
//        
//        // Change working directory to test repo
//        let originalDir = fixture.setupWorkingDirectory()
//        defer { fixture.restoreWorkingDirectory(originalDir) }
//        
//        // Amend a file's metadata
//        let config = try Tuzuru.loadConfiguration(from: "tuzuru.json")
//        let tuzuru = try Tuzuru(fileManager: FileManager.default, configuration: config)
//        
//        let testFilePath = "contents/technology/swift-basics-for-beginners.md"
//        try await tuzuru.amendFile(
//            filePath: testFilePath,
//            newDate: "2024-03-01",
//            newAuthor: "Integration Test Author"
//        )
//        
//        // Load sources - should pick up amended metadata from git
//        let source = try await tuzuru.loadSources(config.sourceLayout)
//        
//        // Find the amended post
//        let swiftPost = source.posts.first { $0.path.string.contains("swift-basics-for-beginners") }
//        #expect(swiftPost != nil)
//        
//        // Verify amended metadata is used
//        #expect(swiftPost?.author == "Integration Test Author")
//        
//        // Check that the date was updated (should be March 1, 2024)
//        let calendar = Calendar.current
//        let publishedDate = swiftPost?.publishedAt
//        #expect(publishedDate != nil)
//        
//        if let date = publishedDate {
//            let components = calendar.dateComponents([.year, .month, .day], from: date)
//            #expect(components.year == 2024)
//            #expect(components.month == 3)
//            #expect(components.day == 1)
//        }
//        
//        // Generate blog and verify output contains amended metadata
//        let _ = try await tuzuru.generate(source)
//        
//        // Read generated HTML and verify it contains amended author
//        let blogDir = fixture.tempPath.appending("blog")
//        let postFiles = try FileManager.default.contentsOfDirectory(atPath: blogDir.string)
//        let swiftPostHTML = postFiles.first { $0.contains("swift-basics") && $0.hasSuffix(".html") }
//        
//        if let htmlFile = swiftPostHTML {
//            let htmlPath = blogDir.appending(htmlFile)
//            let htmlContent = try String(contentsOfFile: htmlPath.string, encoding: .utf8)
//            #expect(htmlContent.contains("Integration Test Author"))
//        }
//    }
//    
//    @Test
//    func testDisplayPathGeneration() async throws {
//        let fixture = GitRepositoryFixture.shared
//        let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
//        try fixture.copyFixtures(from: fixturesPath)
//        
//        // Create initial commit
//        try fixture.createCommit(message: "Initial commit with demo blog content")
//        
//        // Change working directory to test repo
//        let originalDir = fixture.setupWorkingDirectory()
//        defer { fixture.restoreWorkingDirectory(originalDir) }
//        
//        // Load configuration and create Tuzuru instance
//        let config = try Tuzuru.loadConfiguration(from: "tuzuru.json")
//        let tuzuru = try Tuzuru(fileManager: FileManager.default, configuration: config)
//        
//        // Load sources
//        let source = try await tuzuru.loadSources(config.sourceLayout)
//        
//        // Generate display paths
//        let displayPaths = tuzuru.generateDisplayPaths(for: source)
//        
//        #expect(displayPaths.count == source.posts.count)
//        #expect(displayPaths.count > 0)
//        
//        // Verify paths are reasonable (should contain file names without .md extension)
//        let swiftPath = displayPaths.first { $0.contains("swift-basics") }
//        #expect(swiftPath != nil)
//        #expect(swiftPath?.hasSuffix(".html") == true)
//    }
//    
//    @Test
//    func testBlogInitializationInGitRepo() async throws {
//        let fixture = GitRepositoryFixture.shared
//        // Change working directory to test repo
//        let originalDir = fixture.setupWorkingDirectory()
//        defer { fixture.restoreWorkingDirectory(originalDir) }
//        
//        // Initialize blog in git repository
//        try await Tuzuru.initializeBlog(at: fixture.tempPath)
//        
//        // Verify required files and directories were created
//        #expect(FileManager.default.fileExists(atPath: "tuzuru.json"))
//        #expect(FileManager.default.fileExists(atPath: "contents"))
//        #expect(FileManager.default.fileExists(atPath: "contents/unlisted"))
//        #expect(FileManager.default.fileExists(atPath: "templates"))
//        #expect(FileManager.default.fileExists(atPath: "assets"))
//        
//        // Verify we can load the configuration
//        let config = try Tuzuru.loadConfiguration(from: nil)
//        #expect(config.metadata.blogName.isEmpty == false)
//        
//        // Commit the initialized blog
//        try fixture.createCommit(message: "Initialize blog with Tuzuru")
//        
//        // Verify we can create a Tuzuru instance with the initialized setup
//        let tuzuru = try Tuzuru(fileManager: FileManager.default, configuration: config)
//        let source = try await tuzuru.loadSources(config.sourceLayout)
//        
//        // Should have no posts initially
//        #expect(source.posts.count == 0)
//        
//        // Should be able to generate (empty blog)
//        let _ = try await tuzuru.generate(source)
//        #expect(FileManager.default.fileExists(atPath: "blog"))
//    }
//}
