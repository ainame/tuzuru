import Testing
@testable import TuzuruLib

@Suite
struct YAMLFrontMatterParserTests {
    let parser = YAMLFrontMatterParser()

    @Test("Parse valid YAML front matter")
    func parseValidYAMLFrontMatter() throws {
        let markdown = """
        ---
        title: "Test Post"
        date: "2021-01-04T03:24:55Z"
        author: "John Doe"
        ---

        This is the content.
        """

        let result = try parser.parse(markdown)

        #expect(result.metadata.title == "Test Post")
        #expect(result.metadata.date == "2021-01-04T03:24:55Z")
        #expect(result.metadata.author == "John Doe")
        #expect(result.content.trimmingCharacters(in: .whitespacesAndNewlines) == "This is the content.")
    }

    @Test("Parse without front matter")
    func parseWithoutFrontMatter() throws {
        let markdown = "# Regular markdown\n\nNo front matter."
        let result = try parser.parse(markdown)

        #expect(result.metadata.title == nil)
        #expect(result.content == markdown)
    }

    @Test("Missing closing delimiter throws error")
    func missingClosingDelimiter() {
        let markdown = "---\ntitle: \"Broken\"\nContent without closing."

        #expect(throws: YAMLFrontMatterError.missingClosingDelimiter) {
            try parser.parse(markdown)
        }
    }

}
