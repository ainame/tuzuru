import Foundation
import Markdown

struct MarkdownExcerptWalker: MarkupWalker {
    let maxLength: Int
    private var hasPassedFirstHeading: Bool = false
    private var _result: String = ""
    var result: String { _result.isEmpty ? "" : _result.prefix(maxLength - 1) + "…" }

    init(maxLength: Int) {
        self.maxLength = maxLength
    }

    mutating func visitText(_ text: Text) {
        if hasPassedFirstHeading == false,
           let heading = text.parent as? Heading,
           heading.level == 1 {
            hasPassedFirstHeading = true
            return
        }

        let remainingCount = maxLength - _result.count
        _result += text.plainText.prefix(remainingCount)

        // If text is part of heading, it's like that there's no puncuation at the end.
        // If there's still space, just append a whitespace.
        if text.parent is Heading, _result.count < maxLength {
            _result += " "
        }
    }
}
