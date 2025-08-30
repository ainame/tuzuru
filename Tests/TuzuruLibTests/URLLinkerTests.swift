import Foundation
import Testing
import Markdown
@testable import TuzuruLib

@Suite
struct URLLinkerTests {
    @Test
    func `No URLs should return original text unchanged`() async throws {
        let rawMarkdown = """
        # Title
        This is a paragraph with no URLs in it.
        Another paragraph with regular text only.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        // Should have the same structure
        #expect(newDocument.childCount == document.childCount)
        
        // Get the paragraph and check its text content
        let paragraph = newDocument.child(at: 1) as! Paragraph
        let text = paragraph.child(at: 0) as! Text
        #expect(text.string == "This is a paragraph with no URLs in it.")
    }
    
    @Test
    func `Single URL should be converted to link`() async throws {
        let rawMarkdown = """
        Visit https://example.com for more info.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 3) // "Visit ", link, " for more info."
        
        // Check text before URL
        let beforeText = paragraph.child(at: 0) as! Text
        #expect(beforeText.string == "Visit ")
        
        // Check the link
        let link = paragraph.child(at: 1) as! Link
        #expect(link.destination == "https://example.com")
        let linkText = link.child(at: 0) as! Text
        #expect(linkText.string == "https://example.com")
        
        // Check text after URL
        let afterText = paragraph.child(at: 2) as! Text
        #expect(afterText.string == " for more info.")
    }
    
    @Test
    func `Multiple URLs in same paragraph should all be converted`() async throws {
        let rawMarkdown = """
        Visit https://apple.com and https://developer.apple.com for resources.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 5) // "Visit ", link1, " and ", link2, " for resources."
        
        // Check first link
        let link1 = paragraph.child(at: 1) as! Link
        #expect(link1.destination == "https://apple.com")
        
        // Check second link  
        let link2 = paragraph.child(at: 3) as! Link
        #expect(link2.destination == "https://developer.apple.com")
    }
    
    @Test
    func `HTTP and HTTPS URLs should both work`() async throws {
        let rawMarkdown = """
        Secure: https://secure.example.com and insecure: http://insecure.example.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 4) // "Secure: ", link1, " and insecure: ", link2
        
        // Check HTTPS link
        let httpsLink = paragraph.child(at: 1) as! Link
        #expect(httpsLink.destination == "https://secure.example.com")
        
        // Check HTTP link
        let httpLink = paragraph.child(at: 3) as! Link
        #expect(httpLink.destination == "http://insecure.example.com")
    }
    
    @Test
    func `URLs with paths and query parameters should work`() async throws {
        let rawMarkdown = """
        Check https://github.com/ainame/Tuzuru/issues?state=open for issues.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        let link = paragraph.child(at: 1) as! Link
        #expect(link.destination == "https://github.com/ainame/Tuzuru/issues?state=open")
    }
    
    @Test
    func `URL at beginning of paragraph should work`() async throws {
        let rawMarkdown = """
        https://example.com is a great website.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 2) // link, " is a great website."
        
        let link = paragraph.child(at: 0) as! Link
        #expect(link.destination == "https://example.com")
    }
    
    @Test
    func `URL at end of paragraph should work`() async throws {
        let rawMarkdown = """
        Visit my website at https://example.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 2) // "Visit my website at ", link
        
        let link = paragraph.child(at: 1) as! Link
        #expect(link.destination == "https://example.com")
    }
    
    @Test
    func `Multiple paragraphs with URLs should all be processed`() async throws {
        let rawMarkdown = """
        First paragraph with https://first.com link.
        
        Second paragraph with https://second.com link.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        #expect(newDocument.childCount == 2)
        
        // Check first paragraph
        let paragraph1 = newDocument.child(at: 0) as! Paragraph
        let link1 = paragraph1.child(at: 1) as! Link
        #expect(link1.destination == "https://first.com")
        
        // Check second paragraph
        let paragraph2 = newDocument.child(at: 1) as! Paragraph
        let link2 = paragraph2.child(at: 1) as! Link
        #expect(link2.destination == "https://second.com")
    }
    
    @Test
    func `URLs in headings should not be processed`() async throws {
        let rawMarkdown = """
        # Visit https://example.com
        
        Regular paragraph text.
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        // Heading should remain unchanged (URLLinker only processes paragraphs)
        let heading = newDocument.child(at: 0) as! Heading
        let headingText = heading.child(at: 0) as! Text
        #expect(headingText.string == "Visit https://example.com")
    }
    
    @Test
    func `Existing links should not be double-processed`() async throws {
        let rawMarkdown = """
        Visit [my site](https://example.com) and also https://other.com
        """

        let document = Document(parsing: rawMarkdown)
        var urlLinker = URLLinker()
        let newDocument = urlLinker.visit(document)! as! Document
        
        let paragraph = newDocument.child(at: 0) as! Paragraph
        #expect(paragraph.childCount == 4) // "Visit ", existing link, " and also ", new link
        
        // First link should remain as original markdown link
        let existingLink = paragraph.child(at: 1) as! Link
        #expect(existingLink.destination == "https://example.com")
        let existingLinkText = existingLink.child(at: 0) as! Text
        #expect(existingLinkText.string == "my site")
        
        // Second URL should be auto-linked
        let autoLink = paragraph.child(at: 3) as! Link
        #expect(autoLink.destination == "https://other.com")
        let autoLinkText = autoLink.child(at: 0) as! Text
        #expect(autoLinkText.string == "https://other.com")
    }
}