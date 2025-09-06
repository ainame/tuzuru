import Foundation
import Markdown

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

        let liPattern = #"(<li[^>]*>)(.*?)(</li>)"#
        let liRegex = try! NSRegularExpression(pattern: liPattern, options: [.dotMatchesLineSeparators])

        let matches = liRegex.matches(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count))
        if matches.isEmpty { return html }

        var result = String()
        result.reserveCapacity(html.count)

        var lastLocation = html.startIndex

        for match in matches {
            guard let fullRange = Range(match.range, in: html),
                  let openRange = Range(match.range(at: 1), in: html),
                  let innerRange = Range(match.range(at: 2), in: html),
                  let closeRange = Range(match.range(at: 3), in: html) else {
                continue
            }

            // Append content before this <li> block
            result += String(html[lastLocation..<fullRange.lowerBound])

            // Extract parts
            let openTag = String(html[openRange])
            let inner = String(html[innerRange])
            let closeTag = String(html[closeRange])

            // Remove <p> and </p> (with optional attributes/whitespace) anywhere within the inner content
            let pTagRegex = try! NSRegularExpression(
                pattern: #"<\s*/?\s*p(?:\s+[^>]*)?>"#,
                options: [.caseInsensitive]
            )
            let innerNS = inner as NSString
            let cleanedInner = pTagRegex.stringByReplacingMatches(
                in: inner,
                options: [],
                range: NSRange(location: 0, length: innerNS.length),
                withTemplate: ""
            )

            result += openTag
            result += cleanedInner
            result += closeTag

            lastLocation = fullRange.upperBound
        }

        // Append the tail after the last match
        result += String(html[lastLocation...])
        return result
    }
}
