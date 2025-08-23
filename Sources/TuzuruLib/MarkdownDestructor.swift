import Foundation
import Markdown

/// Destruct given markdown document into a title text and document after the first level 1 heading
/// Given document object will be rewritten and title is availabe as a stored property if found.
struct MarkdownDestructor: MarkupRewriter {
    private(set) var title: String? = nil

    mutating func decendInto(_ markup: Markup) -> Markup? {
        let newChildren = markup.children.compactMap {
            return self.visit($0)
        }
        return markup.withUncheckedChildren(newChildren)
    }

    mutating func defaultVisit(_ markup: any Markup) -> Optional<any Markup> {
        if markup is Document {
            return decendInto(markup)
        }

        if title == nil {
            return nil
        }

        return markup
    }

    mutating func visitHeading(_ heading: Heading) -> Optional<any Markup> {
        if title == nil, heading.level == 1 {
            title = heading.plainText
            return nil
        }

        if title == nil {
            return nil
        }

        return heading
    }
}
