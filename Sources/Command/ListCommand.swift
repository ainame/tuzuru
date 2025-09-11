import ArgumentParser
import Foundation
import TuzuruLib

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List blog posts with metadata in CSV format"
    )

    @Option(name: [.long, .customShort("c")], help: "Path to configuration file (default: tuzuru.json)")
    var config: String?

    mutating func run() async throws {
        // Load configuration
        let blogConfig = try Tuzuru.loadConfiguration(from: config)

        // Initialize Tuzuru with configuration
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)
        let tuzuru = try Tuzuru(fileManager: fileManager, configuration: blogConfig)

        // Load and process sources
        let rawSource = try await tuzuru.loadSources(blogConfig.sourceLayout)
        let processedSource = try await tuzuru.processContents(rawSource)

        // Date formatter for output
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone.current

        // Print CSV header: Published At, Author, Title, File Path
        print("\"Published At\", \"Author\", \"Title\", \"File Path\"")

        for post in processedSource.posts.sorted(by: { $0.publishedAt > $1.publishedAt }) {
            let relativePath = extractRelativePath(from: post.path, basePath: blogConfig.sourceLayout.contents)
            let formattedDate = dateFormatter.string(from: post.publishedAt)
            let truncatedTitle = truncateString(post.title, maxLength: 40)

            // Output CSV row with spaces after commas
            let escapedDate = escapeCSVField(formattedDate)
            let escapedAuthor = escapeCSVField(post.author)
            let escapedTitle = escapeCSVField(truncatedTitle)
            let escapedPath = escapeCSVField(relativePath)

            print("\(escapedDate), \(escapedAuthor), \(escapedTitle), \(escapedPath)")
        }
    }

    private func extractRelativePath(from fullPath: FilePath, basePath: FilePath) -> String {
        let fullPathString = fullPath.string
        let basePathString = basePath.string

        if fullPathString.hasPrefix(basePathString) {
            let relativePath = String(fullPathString.dropFirst(basePathString.count))
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }

        return fullPathString
    }

    private func truncateString(_ string: String, maxLength: Int) -> String {
        if string.count <= maxLength {
            return string
        }
        return String(string.prefix(maxLength - 3)) + "..."
    }

    private func escapeCSVField(_ field: String) -> String {
        // If field contains comma, newline, or quote, wrap in quotes and escape internal quotes
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        }
        return field
    }
}
