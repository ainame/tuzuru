import Foundation
import Markdown
import Mustache
import System

/// Handles loading and processing source content from markdown files
struct ContentLoader: Sendable {
    private let configuration: BlogConfiguration
    private let gitWrapper: GitWrapper
    
    init(configuration: BlogConfiguration) {
        self.configuration = configuration
        self.gitWrapper = GitWrapper()
    }

    @concurrent
    func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        let templates = try loadTemplates(templates: sourceLayout.templates)
        var source = Source(title: "", templates: templates, pages: [])

        let markdownFiles = try findMarkdownFiles(fileManager: FileManager(), in: sourceLayout.contents)

        let articles = try await withThrowingTaskGroup { group in
            for markdownPath in markdownFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdownFile(fileManager: fileManager, markdownPath: markdownPath)
                }
            }
            var articles = [Article]()
            while let result = try await group.next(),
                  let result {
                articles.append(result)
            }
            return articles
        }

        // Sort pages by publish date (newest first)
        source.pages.sort { $0.publishedAt > $1.publishedAt }
        
        return source
    }
    
    // MARK: - Private Methods
    
    private func findMarkdownFiles(fileManager: FileManager, in directory: FilePath) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []
        
        let enumerator = fileManager.enumerator(atPath: directory.string)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().hasSuffix(".md") || file.lowercased().hasSuffix(".markdown") {
                markdownFiles.append(directory.appending(file))
            }
        }
        
        return markdownFiles
    }
    
    private func processMarkdownFile(fileManager: FileManager, markdownPath: FilePath) async throws -> Article? {
        let gitLogs = await gitWrapper.logs(for: markdownPath)
        
        // Get the first commit (initial commit) for publish date and author
        let firstCommit = gitLogs.last // logs are in reverse chronological order
        let author = firstCommit?.author ?? "Unknown"
        let publishedAt = firstCommit?.date ?? Date()
        
        // Read and process markdown content
        guard let markdownData = fileManager.contents(atPath: markdownPath.string),
              let markdownContent = String(data: markdownData, encoding: .utf8) else {
            throw TuzuruError.fileNotFound(markdownPath.string)
        }

        let document = Document(parsing: markdownContent)

        // Extract title from markdown file (first # header or filename)
        var destructor = MarkdownDestructor()
        let newDocument = destructor.visit(document)
        let title = destructor.title

        guard let newDocument, let title else {
            print("title is missing in \(markdownPath.string) ")
            return nil
        }

        // Convert markdown to HTML
        var htmlFormatter = HTMLFormatter()
        htmlFormatter.visit(newDocument)

        var walker = MarkdownExcerptWalker(maxLength: 150)
        walker.visit(newDocument)

        return Article(
            path: markdownPath,
            title: title,
            author: author,
            publishedAt: publishedAt,
            excerpt: walker.result,
            content: markdownContent,
            htmlContent: htmlFormatter.result,
        )
    }

    private func loadTemplates(templates: Templates) throws -> LoadedTemplates {
        let fileManager = FileManager()
        guard let layoutData = fileManager.contents(atPath: templates.layoutFile.string),
              let layoutTemplate = String(data: layoutData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.layoutFile.string)
        }

        guard let articleData = fileManager.contents(atPath: templates.articleFile.string),
              let articleTemplate = String(data: articleData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.articleFile.string)
        }

        guard let listData = fileManager.contents(atPath: templates.listFile.string),
              let listTemplate = String(data: listData, encoding: .utf8) else {
            throw TuzuruError.templateNotFound(templates.listFile.string)
        }
        return try LoadedTemplates(
            layout: MustacheTemplate(string: layoutTemplate),
            article: MustacheTemplate(string: articleTemplate),
            list: MustacheTemplate(string: listTemplate),
        )
    }
}
