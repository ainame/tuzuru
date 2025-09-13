import ArgumentParser
import Foundation
import TuzuruLib
import Wcwidth

private let wcwidth = Wcwidth()

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List blog posts with metadata in a table format"
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

        // Prepare data for table
        var rows: [[String]] = []
        for post in processedSource.posts.sorted(by: { $0.publishedAt > $1.publishedAt }) {
            let relativePath = extractRelativePath(from: post.path, basePath: blogConfig.sourceLayout.contents)
            let formattedDate = dateFormatter.string(from: post.publishedAt)
            let truncatedTitle = truncateString(post.title, maxLength: 40)
            let year = String(Calendar.current.component(.year, from: post.publishedAt))
            let category = extractCategory(from: post.path, basePath: blogConfig.sourceLayout.contents)

            rows.append([formattedDate, post.author, truncatedTitle, relativePath, year, category])
        }

        // Column headers
        let headers = ["Published At", "Author", "Title", "File Path", "Year", "Category"]

        // Print table with borders
        printTableWithBorders(headers: headers, rows: rows)
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

    private func extractCategory(from fullPath: FilePath, basePath: FilePath) -> String {
        let relativePath = extractRelativePath(from: fullPath, basePath: basePath)
        let pathComponents = relativePath.components(separatedBy: "/")
        // If the file is directly in contents (no subdirectory), return empty
        if pathComponents.count <= 1 {
            return ""
        }

        // Return the first directory component as category
        return pathComponents[0]
    }

    private func truncateString(_ string: String, maxLength: Int) -> String {
        if wcwidth(string) <= maxLength {
            return string
        }

        var truncated = ""
        var currentWidth = 0
        let ellipsis = "..."
        let ellipsisWidth = wcwidth(ellipsis)
        let targetWidth = maxLength - ellipsisWidth

        for char in string {
            let charWidth = wcwidth(char)
            if currentWidth + charWidth > targetWidth {
                break
            }
            truncated.append(char)
            currentWidth += charWidth
        }

        return truncated + ellipsis
    }

    private func printTableWithBorders(headers: [String], rows: [[String]]) {
        // Calculate column widths
        var columnWidths = headers.map { wcwidth($0) }

        for row in rows {
            for (index, cell) in row.enumerated() {
                let cellWidth = wcwidth(cell)
                if cellWidth > columnWidths[index] {
                    columnWidths[index] = cellWidth
                }
            }
        }

        // Print top border
        printHorizontalBorder(columnWidths: columnWidths, position: .top)

        // Print header
        printRow(cells: headers, columnWidths: columnWidths)

        // Print header separator
        printHorizontalBorder(columnWidths: columnWidths, position: .middle)

        // Print data rows
        for row in rows {
            printRow(cells: row, columnWidths: columnWidths)
        }

        // Print bottom border
        printHorizontalBorder(columnWidths: columnWidths, position: .bottom)
    }

    private enum BorderPosition {
        case top, middle, bottom
    }

    private func printHorizontalBorder(columnWidths: [Int], position: BorderPosition) {
        let (left, junction, right, horizontal) = switch position {
        case .top: ("┌", "┬", "┐", "─")
        case .middle: ("├", "┼", "┤", "─")
        case .bottom: ("└", "┴", "┘", "─")
        }

        var border = left
        for (index, width) in columnWidths.enumerated() {
            border += String(repeating: horizontal, count: width + 2) // +2 for padding
            if index < columnWidths.count - 1 {
                border += junction
            }
        }
        border += right

        print(border)
    }

    private func printRow(cells: [String], columnWidths: [Int]) {
        var row = "│"
        for (index, cell) in cells.enumerated() {
            let cellWidth = wcwidth(cell)
            let padding = columnWidths[index] - cellWidth
            row += " \(cell)\(String(repeating: " ", count: padding)) │"
        }
        print(row)
    }
}
