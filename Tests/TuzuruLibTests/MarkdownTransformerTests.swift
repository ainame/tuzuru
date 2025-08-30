import Testing
@testable import TuzuruLib

@Suite
struct MarkdownTransformerTests {
    let transformer = MarkdownTransformer()
    
    @Test("Add title header to content without header")
    func addTitleHeaderToContentWithoutHeader() {
        let content = "This is content without a header."
        let result = transformer.addTitleHeader(to: content, title: "My Title")
        let expected = "# My Title\n\nThis is content without a header."
        
        #expect(result == expected)
    }
    
    @Test("Don't add title when H1 already exists")
    func addTitleHeaderWhenH1AlreadyExists() {
        let content = "# Existing Title\n\nContent here."
        let result = transformer.addTitleHeader(to: content, title: "New Title")
        
        #expect(result == content)
    }
    
    @Test("Remove front matter")
    func removeFrontMatter() {
        let content = "---\ntitle: \"Test\"\n---\n\nContent after."
        let result = transformer.removeFrontMatter(from: content)
        
        #expect(result == "Content after.")
    }
    
    @Test("Transform with front matter and no H1")
    func transformWithFrontMatterAndNoH1() {
        let content = "---\ntitle: \"Post\"\n---\n\nContent here."
        let result = transformer.transform(content: content, title: "Post")
        let expected = "# Post\n\nContent here."
        
        #expect(result == expected)
    }
    
    @Test("Detect H1 headers", arguments: [
        ("# This is H1", true),
        ("## This is H2", false),
        ("Regular text", false),
    ])
    func hasH1Header(content: String, expected: Bool) {
        #expect(transformer.hasH1Header(in: content) == expected)
    }
}
