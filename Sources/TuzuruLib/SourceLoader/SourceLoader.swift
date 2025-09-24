import Foundation
import Mustache

/// Handles loading raw source content from markdown files (without processing)
struct SourceLoader: Sendable {
    private let configuration: BlogConfiguration
    private let fileManager: FileManagerWrapper
    private let gitLogReader: GitLogReader

    init(
        configuration: BlogConfiguration,
        fileManager: FileManagerWrapper,
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
        gitLogReader = GitLogReader(workingDirectory: fileManager.workingDirectory)
    }

    @Sendable
    func loadSources() async throws -> RawSource {
        let templates = try loadTemplates(templates: configuration.sourceLayout.templates)
        var source = RawSource(metadata: configuration.metadata, templates: templates, posts: [], years: [], categories: [])

        // Find markdown files in contents directory (excluding unlisted subdirectory)
        let contentsFiles = try findMarkdowns(in: configuration.sourceLayout.contents, excludePath: configuration.sourceLayout.unlisted)
        // Find markdown files in unlisted directory
        let unlistedFiles = try findMarkdowns(in: configuration.sourceLayout.unlisted)

        source.posts = try await withThrowingTaskGroup(of: RawPost?.self) { group in
            // Process regular content files
            for markdownPath in contentsFiles {
                group.addTask {
                    try await process(markdownPath: markdownPath, isUnlisted: false)
                }
            }

            // Process unlisted content files
            for markdownPath in unlistedFiles {
                group.addTask {
                    try await process(markdownPath: markdownPath, isUnlisted: true)
                }
            }

            var posts = [RawPost]()
            for try await result in group {
                if let result {
                    posts.append(result)
                }
            }
            return posts
        }

        // Sort pages by publish date (newest first)
        source.posts.sort { $0.publishedAt != $1.publishedAt ? $0.publishedAt > $1.publishedAt : $0.path.string > $1.path.string }

        // Extract years and categories from posts (using raw posts)
        source.years = extractYears(from: source.posts)
        source.categories = extractCategories(from: source.posts)

        return source
    }

    // MARK: - Private Methods

    private func extractYears(from posts: [RawPost]) -> [String] {
        // Extract years from listed posts only
        let listedPosts = posts.filter { !$0.isUnlisted }
        let calendar = Calendar.current
        let yearSet = Set(listedPosts.map { post in
            String(calendar.component(.year, from: post.publishedAt))
        })
        return yearSet.sorted(by: >)
    }

    private func extractCategories(from posts: [RawPost]) -> [String] {
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
            let pathComponents = FilePath(relativePath).components

            // Skip posts directly in contents root (no directory)
            guard let topLevelDirectory = pathComponents.first?.string else { continue }

            // Skip imported directory (based on configuration)
            let importedDirName = configuration.sourceLayout.imported.lastComponent?.string
            if topLevelDirectory == importedDirName {
                continue
            }

            categorySet.insert(topLevelDirectory)
        }
        return categorySet.sorted()
    }

    private func findMarkdowns(in directory: FilePath, excludePath: FilePath? = nil) throws -> [FilePath] {
        var markdownFiles: [FilePath] = []

        // Check if directory exists, if not, return empty array
        guard fileManager.fileExists(atPath: directory) else {
            return markdownFiles
        }

        // Check for year-based directory conflicts only in contents directory
        if directory == configuration.sourceLayout.contents {
            try checkForYearDirectoryConflicts(in: directory)
        }

        let enumerator = fileManager.enumerator(atPath: directory)
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

    private func process(markdownPath: FilePath, isUnlisted: Bool) async throws -> RawPost? {
        let baseCommit = await gitLogReader.baseCommit(for: markdownPath)

        // Get author and publish date from the base commit (either marker commit or original first commit)
        let author = baseCommit?.author ?? "Unknown"
        let publishedAt = baseCommit?.date ?? Date()

        // Read raw markdown content
        guard let markdownData = fileManager.contents(atPath: markdownPath),
              let markdownContent = String(data: markdownData, encoding: .utf8)
        else {
            throw TuzuruError.fileNotFound(markdownPath.string)
        }

        return RawPost(
            path: markdownPath,
            author: author,
            publishedAt: publishedAt,
            content: markdownContent,
            isUnlisted: isUnlisted
        )
    }

    private func checkForYearDirectoryConflicts(in directory: FilePath) throws {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory) else {
            return // Directory doesn't exist or is empty, no conflict possible
        }

        for item in contents {
            let itemPath = directory.appending(item.string)
            var isDirectory = false
            let fileExists = fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory)
            if fileExists && isDirectory {
                if item.string.wholeMatch(of: /\d\d\d\d/) != nil {
                    throw TuzuruError.yearDirectoryConflict("Directory '\(item)' conflicts with yearly list generation. Year-based directories are reserved for automatically generated yearly index pages.")
                }
            }
        }
    }

    private func loadTemplates(templates: BlogTemplates) throws -> MustacheLibrary {
        var library = MustacheLibrary()
        try loadTemplate(filePath: templates.layout, for: "layout", into: &library)
        try loadTemplate(filePath: templates.post, for: "post", into: &library)
        try loadTemplate(filePath: templates.list, for: "list", into: &library)
        return library
    }

    private func loadTemplate(filePath: FilePath, for name: String, into library: inout MustacheLibrary) throws {
        guard let data = fileManager.contents(atPath: filePath) else {
            throw TuzuruError.templateNotFound(filePath.string)
        }
        try library.register(MustacheTemplate(string: String(decoding: data, as: UTF8.self)), named: name)
    }
}
