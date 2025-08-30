import Testing
@testable import TuzuruLib

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
    
    @Test("Parse Hugo and Jekyll date formats", arguments: [
        // Hugo formats
        ("2023-10-15T13:18:50-07:00", true),  // Hugo with timezone offset
        ("2023-10-15T13:18:50-0700", true),   // Hugo with timezone offset (short)
        ("2023-10-15T13:18:50Z", true),       // Hugo UTC
        ("2023-10-15T13:18:50", true),        // Hugo without timezone
        ("2023-10-15", true),                 // Hugo date only
        ("15 Oct 2023", true),                // Hugo alternative format
        // Jekyll formats
        ("2025-06-05 08:31:19 +0700", true),  // Jekyll with timezone
        ("2025-06-05 08:31:19", true),        // Jekyll without timezone
        ("2025-06-05", true),                 // Jekyll date only
        // Invalid formats
        ("invalid date", false),
        ("2021-13-04", false),                // Invalid month
        ("", false),
    ])
    func parseDateFormats(dateString: String, shouldSucceed: Bool) {
        let result = parser.parseDate(dateString)
        #expect((result != nil) == shouldSucceed, "Date parsing for '\(dateString)' should \(shouldSucceed ? "succeed" : "fail")")
    }
}