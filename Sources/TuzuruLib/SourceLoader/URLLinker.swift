import Foundation
import Markdown

struct URLLinker: MarkupRewriter {
    mutating func decendInto(_ markup: Markup) -> Markup? {
        let newChildren = markup.children.compactMap {
            visit($0)
        }
        return markup.withUncheckedChildren(newChildren)
    }

    mutating func defaultVisit(_ markup: any Markup) -> (any Markup)? {
        if markup is Document {
            return decendInto(markup)
        }

        return markup
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> (any Markup)? {
        // Process all children and collect inline elements
        var newInlineElements: [InlineMarkup] = []
        
        for child in paragraph.children {
            if let textChild = child as? Text {
                let processedElements = processTextForURLs(textChild)
                newInlineElements.append(contentsOf: processedElements)
            } else if let inlineChild = child as? InlineMarkup {
                newInlineElements.append(inlineChild)
            }
        }
        
        return paragraph.withUncheckedChildren(newInlineElements)
    }

    private func processTextForURLs(_ text: Text) -> [InlineMarkup] {
        let content = text.string
        let urlRegex = /https?:\/\/[^\s<>"{}|\\^`\[\]]+/
        
        let matches = content.matches(of: urlRegex)
        
        // If no URLs found, return original text
        if matches.isEmpty {
            return [text]
        }
        
        var result: [InlineMarkup] = []
        var lastIndex = content.startIndex
        
        for match in matches {
            // Add text before URL
            if lastIndex < match.range.lowerBound {
                let beforeText = String(content[lastIndex..<match.range.lowerBound])
                if !beforeText.isEmpty {
                    result.append(Text(beforeText))
                }
            }
            
            // Create link from URL
            let url = String(content[match.range])
            let linkChildren: [InlineMarkup] = [Text(url)]
            let link = Link(destination: url).withUncheckedChildren(linkChildren) as! Link
            result.append(link)
            
            lastIndex = match.range.upperBound
        }
        
        // Add remaining text after last URL
        if lastIndex < content.endIndex {
            let afterText = String(content[lastIndex...])
            if !afterText.isEmpty {
                result.append(Text(afterText))
            }
        }
        
        return result
    }
}