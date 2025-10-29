import Foundation
import Testing
import Markdown
@testable import TuzuruLib

@Suite
struct URLLinkerTests {
    @Test
    func testNoURLsShouldReturnOriginalTextUnchanged() async throws {
        let rawMarkdown = """
        # Title
        This is a paragraph with no URLs in it.
        Another paragraph with regular text only.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        // Should have the same structure
        #expect(newDocument.childCount == document.childCount)

        // Get the paragraph and check its text content
        let paragraph = try #require(newDocument.child(at: 1) as? Paragraph)
        let text = try #require(paragraph.child(at: 0) as? Text)
        #expect(text.string == "This is a paragraph with no URLs in it.")
    }

    @Test
    func testSingleURLShouldBeConvertedToLink() async throws {
        let rawMarkdown = """
        Visit https://example.com for more info.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 3) // "Visit ", link, " for more info."

        // Check text before URL
        let beforeText = try #require(paragraph.child(at: 0) as? Text)
        #expect(beforeText.string == "Visit ")

        // Check the link
        let link = try #require(paragraph.child(at: 1) as? Link)
        #expect(link.destination == "https://example.com")
        let linkText = try #require(link.child(at: 0) as? Text)
        #expect(linkText.string == "https://example.com")

        // Check text after URL
        let afterText = try #require(paragraph.child(at: 2) as? Text)
        #expect(afterText.string == " for more info.")
    }

    @Test
    func testMultipleURLsInSameParagraphShouldAllBeConverted() async throws {
        let rawMarkdown = """
        Visit https://apple.com and https://developer.apple.com for resources.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 5) // "Visit ", link1, " and ", link2, " for resources."

        // Check first link
        let link1 = try #require(paragraph.child(at: 1) as? Link)
        #expect(link1.destination == "https://apple.com")

        // Check second link
        let link2 = try #require(paragraph.child(at: 3) as? Link)
        #expect(link2.destination == "https://developer.apple.com")
    }

    @Test
    func testHTTPAndHTTPSURLsShouldBothWork() async throws {
        let rawMarkdown = """
        Secure: https://secure.example.com and insecure: http://insecure.example.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 4) // "Secure: ", link1, " and insecure: ", link2

        // Check HTTPS link
        let httpsLink = try #require(paragraph.child(at: 1) as? Link)
        #expect(httpsLink.destination == "https://secure.example.com")

        // Check HTTP link
        let httpLink = try #require(paragraph.child(at: 3) as? Link)
        #expect(httpLink.destination == "http://insecure.example.com")
    }

    @Test
    func testURLsWithPathsAndQueryParametersShouldWork() async throws {
        let rawMarkdown = """
        Check https://github.com/ainame/Tuzuru/issues?state=open for issues.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        let link = try #require(paragraph.child(at: 1) as? Link)
        #expect(link.destination == "https://github.com/ainame/Tuzuru/issues?state=open")
    }

    @Test
    func testURLAtBeginningOfParagraphShouldWork() async throws {
        let rawMarkdown = """
        https://example.com is a great website.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 2) // link, " is a great website."

        let link = try #require(paragraph.child(at: 0) as? Link)
        #expect(link.destination == "https://example.com")
    }

    @Test
    func testURLAtEndOfParagraphShouldWork() async throws {
        let rawMarkdown = """
        Visit my website at https://example.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 2) // "Visit my website at ", link

        let link = try #require(paragraph.child(at: 1) as? Link)
        #expect(link.destination == "https://example.com")
    }

    @Test
    func testMultipleParagraphsWithURLsShouldAllBeProcessed() async throws {
        let rawMarkdown = """
        First paragraph with https://first.com link.

        Second paragraph with https://second.com link.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        #expect(newDocument.childCount == 2)

        // Check first paragraph
        let paragraph1 = try #require(newDocument.child(at: 0) as? Paragraph)
        let link1 = try #require(paragraph1.child(at: 1) as? Link)
        #expect(link1.destination == "https://first.com")

        // Check second paragraph
        let paragraph2 = try #require(newDocument.child(at: 1) as? Paragraph)
        let link2 = try #require(paragraph2.child(at: 1) as? Link)
        #expect(link2.destination == "https://second.com")
    }

    @Test
    func testURLsInHeadingsShouldNotBeProcessed() async throws {
        let rawMarkdown = """
        # Visit https://example.com

        Regular paragraph text.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        // Heading should remain unchanged (URLLinker only processes paragraphs)
        let heading = try #require(newDocument.child(at: 0) as? Heading)
        let headingText = try #require(heading.child(at: 0) as? Text)
        #expect(headingText.string == "Visit https://example.com")
    }

    @Test
    func testExistingLinksShouldNotBeDoubleProcessed() async throws {
        let rawMarkdown = """
        Visit [my site](https://example.com) and also https://other.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = try #require(urlLinker.visit(document) as? Document)

        let paragraph = try #require(newDocument.child(at: 0) as? Paragraph)
        #expect(paragraph.childCount == 4) // "Visit ", existing link, " and also ", new link

        // First link should remain as original markdown link
        let existingLink = try #require(paragraph.child(at: 1) as? Link)
        #expect(existingLink.destination == "https://example.com")
        let existingLinkText = try #require(existingLink.child(at: 0) as? Text)
        #expect(existingLinkText.string == "my site")

        // Second URL should be auto-linked
        let autoLink = try #require(paragraph.child(at: 3) as? Link)
        #expect(autoLink.destination == "https://other.com")
        let autoLinkText = try #require(autoLink.child(at: 0) as? Text)
        #expect(autoLinkText.string == "https://other.com")
    }
}
