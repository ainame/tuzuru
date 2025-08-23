import Foundation
import Testing
import Markdown
@testable import TuzuruLib

@Suite
struct MarkdownExcerptWalkerTests {
    @Test
    func `Remove children node up to the first heading`() async throws {
        let rawMarkdown = """
        # 1. Title
        ## 2. 2nd heading 2
        (3.) body 1
        # 4. Invalid Title
        (5.) body 2
        ## 6. 2nd heading 3
        (7.) body 3
        """

        let document = Document(parsing: rawMarkdown)
        var walker = MarkdownExcerptWalker(maxLength: 20)
        walker.visit(document)
        #expect(walker.result == "2. 2nd heading 2(3.)")
    }
}
