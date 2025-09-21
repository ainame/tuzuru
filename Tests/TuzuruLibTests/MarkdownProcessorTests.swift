import Testing
import Foundation
@testable import TuzuruLib

@Suite("MarkdownProcessor Tests")
struct MarkdownProcessorTests {
    
    @Test("Process markdown with H1 title")
    func testProcessMarkdownWithH1Title() throws {
        let processor = MarkdownProcessor()
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: "# Actual Title\n\nThis is the content of the post.",
            isUnlisted: false
        )
        
        let processedPost = try processor.process(rawPost)
        
        #expect(processedPost.title == "Actual Title")
        #expect(processedPost.htmlContent.contains("<p>This is the content of the post.</p>"))
        #expect(!processedPost.excerpt.isEmpty)
        #expect(processedPost.author == "Test Author")
        #expect(processedPost.content == rawPost.content) // Original content should be preserved
    }
    
    @Test("Process markdown without H1 title throws error")
    func testProcessMarkdownWithoutH1Title() throws {
        let processor = MarkdownProcessor()
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: "## Subtitle\n\nThis is the content without H1.",
            isUnlisted: false
        )
        
        // Should throw an error when no H1 title is found
        #expect(throws: TuzuruError.self) {
            try processor.process(rawPost)
        }
    }
    
    @Test("Process markdown with URL conversion")
    func testProcessMarkdownWithURLs() throws {
        let processor = MarkdownProcessor()
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: "# Test\n\nVisit https://example.com for more info.",
            isUnlisted: false
        )
        
        let processedPost = try processor.process(rawPost)
        
        #expect(processedPost.htmlContent.contains("<a href=\"https://example.com\">https://example.com</a>"))
        #expect(processedPost.title == "Test")
    }
    
    @Test("Process markdown with code blocks")
    func testProcessMarkdownWithCodeBlocks() throws {
        let processor = MarkdownProcessor()
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: "# Code Example\n\n```swift\nlet html = \"<p>test</p>\"\n```",
            isUnlisted: false
        )
        
        let processedPost = try processor.process(rawPost)
        
        #expect(processedPost.htmlContent.contains("<code"))
        #expect(processedPost.htmlContent.contains("&lt;p&gt;test&lt;/p&gt;")) // HTML should be escaped in code blocks
        #expect(processedPost.title == "Code Example")
    }
    
    @Test("Process generates excerpt")
    func testProcessGeneratesExcerpt() throws {
        let processor = MarkdownProcessor()
        let longContent = "# Test\n\n" + String(repeating: "This is a long paragraph with many words that should be truncated. ", count: 10)
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: longContent,
            isUnlisted: false
        )
        
        let processedPost = try processor.process(rawPost)
        
        #expect(!processedPost.excerpt.isEmpty)
        #expect(processedPost.excerpt.count <= 150) // Should be limited to 150 characters
        #expect(processedPost.title == "Test")
    }
    
    @Test("Process preserves original post metadata")
    func testProcessPreservesMetadata() throws {
        let processor = MarkdownProcessor()
        let testDate = Date()
        let rawPost = RawPost(
            path: FilePath("/test/nested/post.md"),
            author: "Original Author",
            publishedAt: testDate,
            content: "# New Title\n\nContent here.",
            isUnlisted: true
        )
        
        let processedPost = try processor.process(rawPost)
        
        #expect(processedPost.path == FilePath("/test/nested/post.md"))
        #expect(processedPost.author == "Original Author")
        #expect(processedPost.publishedAt == testDate)
        #expect(processedPost.isUnlisted == true)
        #expect(processedPost.title == "New Title") // Title should be updated from H1
    }

    @Test("Process markdown link inside list preserves surrounding spaces")
    func testMarkdownLinkInListPreservesSpaces() throws {
        let processor = MarkdownProcessor()
        let rawPost = RawPost(
            path: FilePath("/test/post.md"),
            author: "Test Author",
            publishedAt: Date(),
            content: "# Links\n\n- prefix [example](https://example.com) suffix",
            isUnlisted: false
        )

        let processedPost = try processor.process(rawPost)

        #expect(processedPost.htmlContent.contains("<li>prefix <a href=\"https://example.com\">example</a> suffix</li>"))
        #expect(!processedPost.htmlContent.contains("<li><p>"))
    }
}
