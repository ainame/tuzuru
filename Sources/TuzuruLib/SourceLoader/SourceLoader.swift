import Foundation
import Markdown
import Mustache
import System

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

        let markdownFiles = try findMarkdownFiles(fileManager: FileManager(), in: configuration.sourceLayout.contents)

        source.posts = try await withThrowingTaskGroup(of: Post?.self) { group in
            for markdownPath in markdownFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdownFile(fileManager: fileManager, markdownPath: markdownPath)
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
        source.posts.sort { $0.publishedAt > $1.publishedAt && $0.title > $0.title }

        return source
    }

    // MARK: - Private Methods

    private func findMarkdownFiles(fileManager: FileManager, in directory: FilePath) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []

        // Check for year-based directory conflicts
        try checkForYearDirectoryConflicts(fileManager: fileManager, in: directory)

        let enumerator = fileManager.enumerator(atPath: directory.string)
        while let file = enumerator?.nextObject() as? String {
            if file.lowercased().hasSuffix(".md") || file.lowercased().hasSuffix(".markdown") {
                markdownFiles.append(directory.appending(file))
            }
        }

        return markdownFiles
    }

    private func processMarkdownFile(fileManager: FileManager, markdownPath: FilePath) async throws -> Post? {
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

        return Post(
            path: markdownPath,
            title: title,
            author: author,
            publishedAt: publishedAt,
            excerpt: walker.result,
            content: markdownContent,
            htmlContent: htmlFormatter.result,
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
