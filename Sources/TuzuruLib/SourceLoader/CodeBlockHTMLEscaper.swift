import Foundation
import Markdown

struct CodeBlockHTMLEscaper: MarkupRewriter {
    mutating func descendInto(_ markup: Markup) -> Markup? {
        let newChildren = markup.children.compactMap {
            visit($0)
        }
        return markup.withUncheckedChildren(newChildren)
    }

    mutating func defaultVisit(_ markup: any Markup) -> (any Markup)? {
        if markup is Document {
            return descendInto(markup)
        }

        return markup
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> (any Markup)? {
        var codeBlock = codeBlock
        codeBlock.code = escapeHTML(codeBlock.code)
        return codeBlock
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
