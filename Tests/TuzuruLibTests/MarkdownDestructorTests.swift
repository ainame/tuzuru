import Foundation
import Testing
import Markdown
@testable import TuzuruLib

@Suite
struct MarkdownDestructorTests {
    @Test
    func removeChildrenNodeUpToFirstHeading() async throws {
        let rawMarkdown = """
        (1.) paragraph 1
        ## 2. 2nd heading 1
        # 3. Title
        ## 4. 2nd heading 2
        (5.) body 1
        # 6. Invalid Title
        (7.) body2
        ## 8. 2nd heading 3
        (9.) body 3
        """

        let document = Document(parsing: rawMarkdown)
        var destructor = MarkdownDestructor()
        let newDocument = destructor.visit(document)!
        #expect(destructor.title == "3. Title")
        #expect(newDocument.childCount == 6)
    }
}

