import Foundation
import Markdown
import Mustache

/// Handles loading and processing source content from markdown files
struct SourceLoader: Sendable {
    private let configuration: BlogConfiguration
    private let gitLogReader: GitLogReader

    init(
        configuration: BlogConfiguration,
        fileManager: FileManager = .default,
    ) {
        self.configuration = configuration
        gitLogReader = GitLogReader(
            workingDirectory: FilePath(fileManager.currentDirectoryPath),
        )
    }

    @Sendable
    func loadSources() async throws -> Source {
        let templates = try loadTemplates(fileManager: FileManager(), templates: configuration.sourceLayout.templates)
        var source = Source(metadata: configuration.metadata, templates: templates, posts: [], years: [], categories: [])

        // Find markdown files in contents directory (excluding unlisted subdirectory)
        let contentsFiles = try findMarkdowns(fileManager: FileManager(), in: configuration.sourceLayout.contents, excludePath: configuration.sourceLayout.unlisted)
        // Find markdown files in unlisted directory
        let unlistedFiles = try findMarkdowns(fileManager: FileManager(), in: configuration.sourceLayout.unlisted)

        source.posts = try await withThrowingTaskGroup(of: Post?.self) { group in
            // Process regular content files
            for markdownPath in contentsFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdown(fileManager: fileManager, markdownPath: markdownPath, isUnlisted: false)
                }
            }

            // Process unlisted content files
            for markdownPath in unlistedFiles {
                group.addTask {
                    let fileManager = FileManager()
                    return try await processMarkdown(fileManager: fileManager, markdownPath: markdownPath, isUnlisted: true)
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

        // Extract years and categories from posts
        source.years = extractYears(from: source.posts)
        source.categories = extractCategories(from: source.posts)

        return source
    }

    // MARK: - Private Methods

    private func extractYears(from posts: [Post]) -> [String] {
        // Extract years from listed posts only
        let listedPosts = posts.filter { !$0.isUnlisted }
        let calendar = Calendar.current
        let yearSet = Set(listedPosts.map { post in
            String(calendar.component(.year, from: post.publishedAt))
        })
        return yearSet.sorted(by: >)
    }

    private func extractCategories(from posts: [Post]) -> [String] {
        // Extract top-level directories from listed posts only
        let listedPosts = posts.filter { !$0.isUnlisted }
        var categorySet = Set<String>()

        for post in listedPosts {
            // Get the relative path within the contents directory
            let contentsPath = configuration.sourceLayout.contents.string
            let postPath = post.path.string

            // Remove the contents base path to get the relative path
            guard postPath.hasPrefix(contentsPath) else { continue }
            let relativePath = String(postPath.dropFirst(contentsPath.count + 1)) // +1 for the trailing slash
            let pathComponents = relativePath.split(separator: "/")

            // Skip posts directly in contents root (no directory)
            guard pathComponents.count > 1 else { continue }

            let topLevelDirectory = String(pathComponents[0])

            // Skip imported directory (based on configuration)
            let importedDirName = configuration.sourceLayout.imported.lastComponent?.string
            if topLevelDirectory == importedDirName {
                continue
            }

            categorySet.insert(topLevelDirectory)
        }
        return categorySet.sorted()
    }

    private func findMarkdowns(fileManager: FileManager, in directory: FilePath, excludePath: FilePath? = nil) throws -> [FilePath] {
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

    private func processMarkdown(fileManager: FileManager, markdownPath: FilePath, isUnlisted: Bool) async throws -> Post? {
        let baseCommit = await gitLogReader.baseCommit(for: markdownPath)

        // Get author and publish date from the base commit (either marker commit or original first commit)
        let author = baseCommit?.author ?? "Unknown"
        let publishedAt = baseCommit?.date ?? Date()

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
        // * Convert X post URLs to embed HTML before markdown processing
        let document = Document(parsing: markdownContent)
        var destructor = MarkdownDestructor()
        var xPostConverter = XPostLinkConverter()
        var urlLinker = URLLinker()
        var escaper = CodeBlockHTMLEscaper()
        var htmlFormatter = HTMLFormatter()
        var excerptWalker = MarkdownExcerptWalker(maxLength: 150)

        destructor.visit(document)
            .flatMap { xPostConverter.visit($0) }
            .flatMap { urlLinker.visit($0) }
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

    private func loadTemplates(fileManager: FileManager, templates: BlogTemplates) throws -> MustacheLibrary {
        var library = MustacheLibrary()
        try loadTemplate(fileManager: fileManager, filePath: templates.layout, for: "layout", into: &library)
        try loadTemplate(fileManager: fileManager, filePath: templates.post, for: "post", into: &library)
        try loadTemplate(fileManager: fileManager, filePath: templates.list, for: "list", into: &library)
        return library
    }

    private func loadTemplate(fileManager: FileManager, filePath: FilePath, for name: String, into library: inout MustacheLibrary) throws {
        guard let data = fileManager.contents(atPath: filePath.string) else {
            throw TuzuruError.templateNotFound(filePath.string)
        }
        try library.register(MustacheTemplate(string: String(decoding: data, as: UTF8.self)), named: name)
    }
}
