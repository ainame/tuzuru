import Foundation
import Markdown
import System

/// Handles loading and processing source content from markdown files
struct ContentLoader {
    private let fileManager: FileManager
    private let gitWrapper: GitWrapper
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.gitWrapper = GitWrapper()
    }
    
    func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        var source = Source(title: "", layoutFile: sourceLayout.layoutFile, pages: [])
        
        let markdownFiles = try findMarkdownFiles(in: sourceLayout.contents)

        for markdownPath in markdownFiles {
            if let article = try await processMarkdownFile(markdownPath) {
                source.pages.append(article)
            }
        }
        
        // Sort pages by publish date (newest first)
        source.pages.sort { $0.publishedAt > $1.publishedAt }
        
        return source
    }
    
    // MARK: - Private Methods
    
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
    
    private func processMarkdownFile(_ markdownPath: FilePath) async throws -> Article? {
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
}
