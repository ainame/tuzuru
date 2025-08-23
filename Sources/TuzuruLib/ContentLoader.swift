import Foundation
import System

/// Handles loading and processing source content from markdown files
struct ContentLoader {
    private let fileManager: FileManager
    private let markdownProcessor: MarkdownProcessor
    private let gitWrapper: GitWrapper
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.markdownProcessor = MarkdownProcessor()
        self.gitWrapper = GitWrapper()
    }
    
    func loadSources(_ sourceLayout: SourceLayout) async throws -> Source {
        var source = Source(title: "", layoutFile: sourceLayout.layoutFile, pages: [])
        
        let markdownFiles = try findMarkdownFiles(in: sourceLayout.contents)
        
        for markdownPath in markdownFiles {
            let article = try await processMarkdownFile(markdownPath)
            source.pages.append(article)
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
    
    private func processMarkdownFile(_ markdownPath: FilePath) async throws -> Article {
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
        
        // Extract title from markdown file (first # header or filename)
        let title = try markdownProcessor.extractTitle(from: markdownPath, content: markdownContent)
        
        // Convert markdown to HTML
        let htmlContent = markdownProcessor.convertToHTML(markdownContent)
        
        return Article(
            path: markdownPath,
            title: title,
            author: author,
            publishedAt: publishedAt,
            content: markdownContent,
            htmlContent: htmlContent
        )
    }
}