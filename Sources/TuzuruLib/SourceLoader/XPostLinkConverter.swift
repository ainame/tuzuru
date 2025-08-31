import Foundation
import Markdown

/// Converts X (Twitter) post URLs to embedded tweet HTML
/// Converts direct X.com URLs to Twitter embed format for Tuzuru compatibility
struct XPostLinkConverter: MarkupRewriter {
    
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
                let processedElements = processTextForXPostURLs(textChild)
                newInlineElements.append(contentsOf: processedElements)
            } else if let inlineChild = child as? InlineMarkup {
                newInlineElements.append(inlineChild)
            }
        }
        
        return paragraph.withUncheckedChildren(newInlineElements)
    }

    private func processTextForXPostURLs(_ text: Text) -> [InlineMarkup] {
        let content = text.string
        // Match X.com URLs in the format: https://x.com/username/status/tweetid
        let xPostRegex = /https:\/\/x\.com\/([^\/\s]+)\/status\/(\d+)(?:\?[^\s]*)?/
        
        let matches = content.matches(of: xPostRegex)
        
        // If no X post URLs found, return original text
        if matches.isEmpty {
            return [text]
        }
        
        var result: [InlineMarkup] = []
        var lastIndex = content.startIndex
        
        for match in matches {
            // Add text before X post URL
            if lastIndex < match.range.lowerBound {
                let beforeText = String(content[lastIndex..<match.range.lowerBound])
                if !beforeText.isEmpty {
                    result.append(Text(beforeText))
                }
            }
            
            // Create HTML block from X post URL
            let user = String(match.output.1)
            let id = String(match.output.2)
            
            let embedHTML = generateXEmbedHTML(user: user, id: id)
            let inlineHTML = InlineHTML(embedHTML)
            result.append(inlineHTML)
            
            lastIndex = match.range.upperBound
        }
        
        // Add remaining text after last X post URL
        if lastIndex < content.endIndex {
            let afterText = String(content[lastIndex...])
            if !afterText.isEmpty {
                result.append(Text(afterText))
            }
        }
        
        return result
    }
    
    /// Generate Twitter embed HTML compatible with Twitter's widget system
    private func generateXEmbedHTML(user: String, id: String) -> String {
        return """
        <blockquote class="twitter-tweet" data-dnt="true">
            <p>Loading tweet...</p>
            <a href="https://twitter.com/\(user)/status/\(id)">Tweet by @\(user)</a>
        </blockquote>
        <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
        """
    }
}
