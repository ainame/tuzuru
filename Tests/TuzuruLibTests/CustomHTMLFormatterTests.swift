import Testing
import Foundation
import Markdown

@Suite("CustomHTMLFormatter Tests")
struct CustomHTMLFormatterTests {

    @Test("Removes paragraph for loose list items")
    func testRemovesParagraphInLooseListItem() throws {
        let markdown = """
        # Title

        - First item

        - Second item
        """

        let document = Document(parsing: markdown)
        var formatter = CustomHTMLFormatter()
        formatter.visit(document)
        let html = formatter.result

        #expect(!html.contains("<li><p>"))
        #expect(!html.contains("</p>"))
        #expect(html.contains("First item"))
        #expect(html.contains("Second item"))
    }

    @Test("Removes paragraphs for nested unordered list")
    func testNestedUnorderedListRemovesParagraphs() throws {
        let markdown = """
        # Title

        - Parent item

          - Child A
          - Child B
        """

        let document = Document(parsing: markdown)
        var formatter = CustomHTMLFormatter()
        formatter.visit(document)
        let html = formatter.result

        // No paragraph wrappers should remain in any <li>
        #expect(!html.contains("<li><p>"))
        #expect(!html.contains("</p>"))

        // Parent should directly contain nested <ul>
        #expect(html.contains("<li>Parent item<ul>"))
        // Children should be tight
        #expect(html.contains("<li>Child A</li>"))
        #expect(html.contains("<li>Child B</li>"))
    }

    @Test("Removes paragraphs for ordered parent with unordered children")
    func testOrderedWithUnorderedChildrenRemovesParagraphs() throws {
        let markdown = """
        # Title

        1. Parent step

           - Child 1
           - Child 2
        """

        let document = Document(parsing: markdown)
        var formatter = CustomHTMLFormatter()
        formatter.visit(document)
        let html = formatter.result

        // No paragraph wrappers should remain in any <li>
        #expect(!html.contains("<li><p>"))
        #expect(!html.contains("</p>"))

        // Ensure ordered list parent is tight and nests an unordered list
        #expect(html.contains("<ol>"))
        #expect(html.contains("<li>Parent step<ul>"))
        #expect(html.contains("<li>Child 1</li>"))
        #expect(html.contains("<li>Child 2</li>"))
    }
    @Test("Removes paragraph before nested list")
    func testRemovesParagraphBeforeNestedList() throws {
        let markdown = """
        # Title

        - Parent item

          - Child A
          - Child B
        """

        let document = Document(parsing: markdown)
        var formatter = CustomHTMLFormatter()
        formatter.visit(document)
        let html = formatter.result

        // Ensure the <p> right after <li> is removed but nested list remains
        #expect(!html.contains("<li><p>"))
        #expect(!html.contains("</p>"))
        #expect(html.contains("Parent item"))
    }

    @Test("Removes paragraphs for multi-paragraph list items")
    func testRemovesParagraphsForMultiParagraphItem() throws {
        let markdown = """
        # Title

        - First paragraph in item

          Second paragraph in same item
        """

        let document = Document(parsing: markdown)
        var formatter = CustomHTMLFormatter()
        formatter.visit(document)
        let html = formatter.result

        // All <p> wrappers inside <li> should be removed.
        #expect(!html.contains("<li><p>"))
        #expect(!html.contains("</p>"))
        #expect(html.contains("First paragraph in item"))
        #expect(html.contains("Second paragraph in same item"))
    }
}
