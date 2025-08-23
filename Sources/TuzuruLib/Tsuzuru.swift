import Foundation
import System
import Markdown
import Mustache

public struct Tuzuru {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        var source = Source(title: "", layoutFile: sourceLayout.layoutFile, pages: [])
        let gitWrapper = GitWrapper()
        
        let markdownFiles = try findMarkdownFiles(in: sourceLayout.contents)
        
        for markdownPath in markdownFiles {
            let gitLogs = await gitWrapper.logs(for: markdownPath)
            
            // Get the first commit (initial commit) for publish date and author
            let firstCommit = gitLogs.last // logs are in reverse chronological order
            let author = firstCommit?.author ?? "Unknown"
            let publishedAt = firstCommit?.date ?? Date()
            
            // Read and process markdown content
            guard let markdownData = fileManager.contents(atPath: markdownPath.string),
                  let markdownContent = String(data: markdownData, encoding: .utf8) else {
                continue
            }
            
            // Extract title from markdown file (first # header or filename)
            let title = try extractTitle(from: markdownPath, content: markdownContent)
            
            // Convert markdown to HTML - for now use a basic implementation
            let htmlContent = convertMarkdownToHTML(markdownContent)
            
            let page = Page(
                path: markdownPath,
                title: title,
                author: author,
                publishedAt: publishedAt,
                content: markdownContent,
                htmlContent: htmlContent
            )
            source.pages.append(page)
        }
        
        // Sort pages by publish date (newest first)
        source.pages.sort { $0.publishedAt > $1.publishedAt }
        
        return source
    }

    private func findMarkdownFiles(in directory: FilePath) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []
        
        let enumerator = fileManager.enumerator(atPath: directory.string)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().hasSuffix(".md") || file.lowercased().hasSuffix(".markdown") {
                markdownFiles.append(directory.appending(file))
            }
        }
        
        return markdownFiles
    }
    
    private func extractTitle(from markdownPath: FilePath, content: String) throws -> String {
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
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        // Remove the first # heading (title) since we display it in metadata header
        let contentWithoutTitle = removeFirstHeading(from: markdown)
        let document = Document(parsing: contentWithoutTitle)
        return renderDocumentAsHTML(document)
    }

    
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
                    items += "<li>\(itemContent.trimmingCharacters(in: .whitespacesAndNewlines))</li>\n"
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
                    items += "<li>\(itemContent.trimmingCharacters(in: .whitespacesAndNewlines))</li>\n"
                }
            }
            return "<ol>\n\(items)</ol>\n"
            
        case let thematicBreak as ThematicBreak:
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

    public func generate(_ source: Source) throws -> SiteLayout {
        let siteRoot = FilePath("site")
        
        // Create site directory if it doesn't exist
        try fileManager.createDirectory(atPath: siteRoot.string, withIntermediateDirectories: true)
        
        // Load templates
        guard let layoutData = fileManager.contents(atPath: source.layoutFile.string),
              let layoutTemplate = String(data: layoutData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(source.layoutFile.string)
        }
        
        guard let articleData = fileManager.contents(atPath: "article.html"),
              let articleTemplate = String(data: articleData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound("article.html")
        }
        
        guard let listData = fileManager.contents(atPath: "list.html"),
              let listTemplate = String(data: listData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound("list.html")
        }
        
        // Generate individual article pages
        for page in source.pages {
            try generateArticlePage(page: page, layoutTemplate: layoutTemplate, articleTemplate: articleTemplate, siteRoot: siteRoot)
        }
        
        // Generate list page (index.html)
        try generateListPage(pages: source.pages, layoutTemplate: layoutTemplate, listTemplate: listTemplate, siteRoot: siteRoot)
        
        return SiteLayout(
            root: siteRoot,
            contents: siteRoot,
            assets: siteRoot
        )
    }
    
    private func generateArticlePage(page: Page, layoutTemplate: String, articleTemplate: String, siteRoot: FilePath) throws {
        // Prepare data for article template
        let articleData: [String: Any] = [
            "title": page.title,
            "author": page.author,
            "publishedAt": formatDate(page.publishedAt),
            "body": page.htmlContent
        ]
        
        // Render article template
        let articleMustacheTemplate = try MustacheTemplate(string: articleTemplate)
        let renderedArticle = articleMustacheTemplate.render(articleData)
        
        // Prepare data for layout template
        let layoutData: [String: Any] = [
            "title": page.title,
            "blog_title": "My Blog",
            "content": renderedArticle
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write to file
        let fileName = "\(page.path.lastComponent?.stem ?? "untitled").html"
        let outputPath = siteRoot.appending(fileName)
        try finalHTML.write(to: URL(fileURLWithPath: outputPath.string), atomically: true, encoding: String.Encoding.utf8)
    }
    
    private func generateListPage(pages: [Page], layoutTemplate: String, listTemplate: String, siteRoot: FilePath) throws {
        // Prepare articles data for list template
        let articlesData = pages.map { page -> [String: Any] in
            let articleURL = "\(page.path.lastComponent?.stem ?? "untitled").html"
            
            return [
                "title": page.title,
                "author": page.author,
                "publishedAt": formatDate(page.publishedAt),
                "url": articleURL,
                "excerpt": extractExcerpt(from: page.content)
            ]
        }
        
        let listData: [String: Any] = [
            "articles": articlesData
        ]
        
        // Render list template
        let listMustacheTemplate = try MustacheTemplate(string: listTemplate)
        let renderedList = listMustacheTemplate.render(listData)
        
        // Prepare data for layout template
        let layoutData: [String: Any] = [
            "title": "Blog",
            "blog_title": "My Blog",
            "content": renderedList
        ]
        
        // Render final page
        let layoutMustacheTemplate = try MustacheTemplate(string: layoutTemplate)
        let finalHTML = layoutMustacheTemplate.render(layoutData)
        
        // Write index.html
        let indexPath = siteRoot.appending("index.html")
        try finalHTML.write(to: URL(fileURLWithPath: indexPath.string), atomically: true, encoding: String.Encoding.utf8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func extractExcerpt(from content: String, maxLength: Int = 150) -> String {
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
}

extension String {
    var htmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}