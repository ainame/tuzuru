import Foundation
import Markdown

struct MarkdownExcerptWalker: MarkupWalker {
    let maxLength: Int
    private var _result: String = ""
    var result: String { _result.isEmpty ? "" : (_result + "...") }

    init(maxLength: Int) {
        self.maxLength = maxLength
    }

    mutating func visitText(_ text: Text) {
        let remainingCount = maxLength - _result.count
        _result += text.plainText.prefix(remainingCount)

        // If text is part of heading, it's like that there's no puncuation at the end.
        // If there's still space, just append a whitespace.
        if text.parent is Heading,
           _result.count < maxLength
        {
            _result += " "
        }
    }
}
