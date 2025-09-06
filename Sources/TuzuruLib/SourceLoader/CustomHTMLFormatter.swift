import Foundation
import Markdown

import RegexBuilder

struct CustomHTMLFormatter {
    var result = ""

    mutating func visit(_ document: any Markup) {
        // Use the standard HTMLFormatter to generate HTML
        var htmlFormatter = HTMLFormatter()
        htmlFormatter.visit(document)

        // Post-process the HTML to remove all <p> wrappers inside <li> elements
        result = removeRedundantListItemParagraphs(htmlFormatter.result)
    }

    private func removeRedundantListItemParagraphs(_ html: String) -> String {
        // Goal: remove any <p>...</p> tags that appear inside <li>...</li> while
        // keeping the text content and any nested lists or inline markup.
        // This turns loose list items into tight ones.

        let liRegex = #/(<li[^>]*>)(.*?)(</li>)/#.dotMatchesNewlines()
        
        let processedHTML = html.replacing(liRegex) { match in
            let openTag = String(match.1)
            let inner = String(match.2)
            let closeTag = String(match.3)
            
            // Remove <p> and </p> tags within the inner content
            let pTagRegex = #/<\s*/?\s*p(?:\s+[^>]*)?>/#.ignoresCase()
            var cleanedInner = inner.replacing(pTagRegex, with: "")
            
            // Clean up excessive whitespace around HTML tags but preserve single spaces between text
            let whitespaceRegex = #/\s*(<[^>]+>)\s*/#
            cleanedInner = cleanedInner.replacing(whitespaceRegex) { tagMatch in
                String(tagMatch.1)
            }
            
            // Trim leading and trailing whitespace from the entire inner content
            cleanedInner = cleanedInner.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return openTag + cleanedInner + closeTag
        }
        
        return processedHTML
    }
}
