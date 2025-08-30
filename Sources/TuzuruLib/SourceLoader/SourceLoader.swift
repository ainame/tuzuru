import Foundation
import Markdown
import Mustache

/// Handles loading and processing source content from markdown files
struct SourceLoader: Sendable {
    private let configuration: BlogConfiguration
    private let gitWrapper: GitWrapper

    init(configuration: BlogConfiguration) {
        self.configuration = configuration
        gitWrapper = GitWrapper()
    }

    @concurrent
    func loadSources() async throws -> Source {
        let templates = try loadTemplates(fileManager: FileManager(), templates: configuration.sourceLayout.templates)
        var source = Source(metadata: configuration.metadata, templates: templates, posts: [])

        // Find markdown files in contents directory (excluding unlisted subdirectory)
        let contentsFiles = try findMarkdownFiles(fileManager: FileManager(), in: configuration.sourceLayout.contents, excludePath: configuration.sourceLayout.unlisted)
        // Find markdown files in unlisted directory
        let unlistedFiles = try findMarkdownFiles(fileManager: FileManager(), in: configuration.sourceLayout.unlisted)

        source.posts = try await withThrowingTaskGroup(of: Post?.self) { group in
            // Process regular content files
            for markdownPath in contentsFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdownFile(fileManager: fileManager, markdownPath: markdownPath, isUnlisted: false)
                }
            }
            
            // Process unlisted content files
            for markdownPath in unlistedFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdownFile(fileManager: fileManager, markdownPath: markdownPath, isUnlisted: true)
                }
            }

            var posts = [Post]()
            for try await result in group {
                if let result {
                    posts.append(result)
                }
            }
            return posts
        }

        // Sort pages by publish date (newest first)
        source.posts.sort { $0.publishedAt != $1.publishedAt ? $0.publishedAt > $1.publishedAt : $0.title > $1.title }

        return source
    }

    // MARK: - Private Methods

    private func findMarkdownFiles(fileManager: FileManager, in directory: FilePath, excludePath: FilePath? = nil) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []
        
        // Check if directory exists, if not, return empty array
        guard fileManager.fileExists(atPath: directory.string) else {
            return markdownFiles
        }

        // Check for year-based directory conflicts only in contents directory
        if directory == configuration.sourceLayout.contents {
            try checkForYearDirectoryConflicts(fileManager: fileManager, in: directory)
        }

        let enumerator = fileManager.enumerator(atPath: directory.string)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().hasSuffix(".md") || file.lowercased().hasSuffix(".markdown") {
                let fullPath = directory.appending(file)
                
                // Skip files that are in the excluded path
                if let excludePath = excludePath {
                    let fileComponents = fullPath.components
                    let excludeComponents = excludePath.components
                    
                    // Check if the file is under the excluded path
                    if fileComponents.count > excludeComponents.count {
                        let filePrefix = Array(fileComponents.prefix(excludeComponents.count))
                        if filePrefix.elementsEqual(excludeComponents) {
                            continue // Skip this file
                        }
                    }
                }
                
                markdownFiles.append(fullPath)
            }
        }

        return markdownFiles
    }

    private func processMarkdownFile(fileManager: FileManager, markdownPath: FilePath, isUnlisted: Bool) async throws -> Post? {
        let gitLogs = await gitWrapper.logs(for: markdownPath)

        // Get the first commit (initial commit) for publish date and author
        let firstCommit = gitLogs.last // logs are in reverse chronological order
        let author = firstCommit?.author ?? "Unknown"
        let publishedAt = firstCommit?.date ?? Date()

        // Read and process markdown content
        guard let markdownData = fileManager.contents(atPath: markdownPath.string),
              let markdownContent = String(data: markdownData, encoding: .utf8)
        else {
            throw TuzuruError.fileNotFound(markdownPath.string)
        }

        // * Extract title from markdown file (first # header or filename)
        // * Escape HTML tags in code blocks
        // * Convert Markdown to HTML
        // * Cite first 150 chars
        let document = Document(parsing: markdownContent)
        var destructor = MarkdownDestructor()
        var escaper = CodeBlockHTMLEscaper()
        var htmlFormatter = HTMLFormatter()
        var excerptWalker = MarkdownExcerptWalker(maxLength: 150)

        destructor.visit(document)
            .flatMap { escaper.visit($0) }
            .flatMap {
                // Walk for the same document
                htmlFormatter.visit($0)
                excerptWalker.visit($0)
            }

        guard let title = destructor.title else {
            print("title is missing in \(markdownPath.string) ")
            return nil
        }

        return Post(
            path: markdownPath,
            title: title,
            author: author,
            publishedAt: publishedAt,
            excerpt: excerptWalker.result,
            content: markdownContent,
            htmlContent: htmlFormatter.result,
            isUnlisted: isUnlisted
        )
    }

    private func checkForYearDirectoryConflicts(fileManager: FileManager, in directory: FilePath) throws {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.string) else {
            return // Directory doesn't exist or is empty, no conflict possible
        }

        for item in contents {
            #if canImport(Darwin)
            var isDirectory: ObjCBool = false
            #else
            var isDirectory = false
            #endif

            let itemPath = directory.appending(item)
            let fileExists = fileManager.fileExists(atPath: itemPath.string, isDirectory: &isDirectory)
            #if canImport(Darwin)
            let isDirectoryBool = isDirectory.boolValue
            #else
            let isDirectoryBool = isDirectory
            #endif

            if fileExists && isDirectoryBool {
                if item.wholeMatch(of: /\d\d\d\d/) != nil {
                    throw TuzuruError.yearDirectoryConflict("Directory '\(item)' conflicts with yearly list generation. Year-based directories are reserved for automatically generated yearly index pages.")
                }
            }
        }
    }

    private func loadTemplates(fileManager: FileManager, templates: Templates) throws -> LoadedTemplates {
        guard let layoutData = fileManager.contents(atPath: templates.layoutFile.string),
              let layoutTemplate = String(data: layoutData, encoding: .utf8)
        else {
            throw TuzuruError.templateNotFound(templates.layoutFile.string)
        }

        guard let postData = fileManager.contents(atPath: templates.postFile.string),
              let postTemplate = String(data: postData, encoding: .utf8)
        else {
            throw TuzuruError.templateNotFound(templates.postFile.string)
        }

        guard let listData = fileManager.contents(atPath: templates.listFile.string),
              let listTemplate = String(data: listData, encoding: .utf8)
        else {
            throw TuzuruError.templateNotFound(templates.listFile.string)
        }
        return try LoadedTemplates(
            layout: MustacheTemplate(string: layoutTemplate),
            post: MustacheTemplate(string: postTemplate),
            list: MustacheTemplate(string: listTemplate),
        )
    }
}
