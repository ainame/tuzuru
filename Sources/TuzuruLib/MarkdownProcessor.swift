import Foundation
import Markdown
import System

/// Handles markdown parsing, title extraction, and HTML conversion
struct MarkdownProcessor {

    func extractTitle(from markdownPath: FilePath, content: String) throws -> String {
        // Look for first # header
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("# ") {
                return String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            }
        }

        // Fallback to filename without extension
        return markdownPath.lastComponent?.stem ?? "Untitled"
    }

    func convertToHTML(_ markdown: String) -> String {
        // Remove the first # heading (title) since we display it in metadata header
        let contentWithoutTitle = removeFirstHeading(from: markdown)
        let document = Document(parsing: contentWithoutTitle)
        return renderDocumentAsHTML(document)
    }

    func extractExcerpt(from content: String, maxLength: Int = 150) -> String {
        // Remove markdown syntax for excerpt
        let plainText = content
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "_", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if plainText.count <= maxLength {
            return plainText
        }

        let truncated = String(plainText.prefix(maxLength))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    // MARK: - Private Methods

    private func removeFirstHeading(from markdown: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var resultLines: [String] = []
        var foundFirstHeading = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Skip the first # heading line
            if !foundFirstHeading && trimmedLine.hasPrefix("# ") {
                foundFirstHeading = true
                continue
            }

            resultLines.append(line)
        }

        return resultLines.joined(separator: "\n")
    }

    private func renderDocumentAsHTML(_ document: Document) -> String {
        var html = ""

        for child in document.children {
            html += renderMarkupAsHTML(child)
        }

        return html
    }

    private func renderMarkupAsHTML(_ markup: Markup) -> String {
        switch markup {
        case let heading as Heading:
            let level = heading.level
            let content = renderInlineHTML(heading.children)
            return "<h\(level)>\(content)</h\(level)>\n"

        case let paragraph as Paragraph:
            let content = renderInlineHTML(paragraph.children)
            return "<p>\(content)</p>\n"

        case let codeBlock as CodeBlock:
            let language = codeBlock.language ?? ""
            let code = codeBlock.code.htmlEscaped
            if !language.isEmpty {
                return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"
            } else {
                return "<pre><code>\(code)</code></pre>\n"
            }

        case let blockQuote as BlockQuote:
            var content = ""
            for child in blockQuote.children {
                content += renderMarkupAsHTML(child)
            }
            return "<blockquote>\(content)</blockquote>\n"

        case let list as UnorderedList:
            var items = ""
            for item in list.children {
                if let listItem = item as? ListItem {
                    var itemContent = ""
                    for child in listItem.children {
                        itemContent += renderMarkupAsHTML(child)
                    }
                    items +=
                        "<li>\(itemContent.trimmingCharacters(in: .whitespacesAndNewlines))</li>\n"
                }
            }
            return "<ul>\n\(items)</ul>\n"

        case let list as OrderedList:
            var items = ""
            for item in list.children {
                if let listItem = item as? ListItem {
                    var itemContent = ""
                    for child in listItem.children {
                        itemContent += renderMarkupAsHTML(child)
                    }
                    items +=
                        "<li>\(itemContent.trimmingCharacters(in: .whitespacesAndNewlines))</li>\n"
                }
            }
            return "<ol>\n\(items)</ol>\n"

        case _ as ThematicBreak:
            return "<hr>\n"

        default:
            return ""
        }
    }

    private func renderInlineHTML(_ children: MarkupChildren) -> String {
        var html = ""

        for child in children {
            switch child {
            case let text as Text:
                html += text.string.htmlEscaped

            case let emphasis as Emphasis:
                let content = renderInlineHTML(emphasis.children)
                html += "<em>\(content)</em>"

            case let strong as Strong:
                let content = renderInlineHTML(strong.children)
                html += "<strong>\(content)</strong>"

            case let inlineCode as InlineCode:
                html += "<code>\(inlineCode.code.htmlEscaped)</code>"

            case let link as Link:
                let content = renderInlineHTML(link.children)
                let destination = link.destination?.htmlEscaped ?? ""
                html += "<a href=\"\(destination)\">\(content)</a>"

            case let strikethrough as Strikethrough:
                let content = renderInlineHTML(strikethrough.children)
                html += "<del>\(content)</del>"

            default:
                html += ""
            }
        }

        return html
    }
}

extension String {
    var htmlEscaped: String {
        return
            self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
