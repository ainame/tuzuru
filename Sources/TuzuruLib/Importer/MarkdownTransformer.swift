import Foundation

/// Transforms markdown content by adding title headers and other modifications
struct MarkdownTransformer: Sendable {
    
    /// Adds a title as H1 header to markdown content if not already present
    /// - Parameters:
    ///   - content: The markdown content
    ///   - title: The title to add as H1 header
    /// - Returns: Transformed markdown content with title header
    func addTitleHeader(to content: String, title: String) -> String {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if content is empty
        guard !trimmedContent.isEmpty else {
            return "# \(title)\n"
        }
        
        // Split content into lines
        let lines = trimmedContent.components(separatedBy: .newlines)
        
        // Check if first non-empty line is already an H1 header
        if let firstNonEmptyLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            if firstNonEmptyLine.hasPrefix("# ") {
                // Already has H1 header, return original content
                return trimmedContent
            }
        }
        
        // Add title as H1 header at the beginning
        let titleHeader = "# \(title)"
        
        // Add a blank line after title if content doesn't start with a blank line
        let separator = lines.first?.isEmpty == true ? "\n" : "\n\n"
        
        return titleHeader + separator + trimmedContent
    }
    
    /// Removes any existing YAML front matter from markdown content
    /// - Parameter content: The markdown content potentially containing YAML front matter
    /// - Returns: Content with YAML front matter removed
    func removeFrontMatter(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        
        // Check if content starts with YAML front matter delimiter
        guard lines.first == "---" else {
            return content
        }
        
        // Find the closing delimiter
        var contentStartIndex = 1
        
        for i in 1..<lines.count {
            if lines[i] == "---" {
                contentStartIndex = i + 1
                break
            }
        }
        
        // Return content after front matter
        let contentLines = Array(lines[contentStartIndex...])
        return contentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Transforms markdown content by removing front matter and adding title header
    /// - Parameters:
    ///   - content: The original markdown content with potential YAML front matter
    ///   - title: The title to add as H1 header
    /// - Returns: Transformed markdown content
    func transform(content: String, title: String) -> String {
        let contentWithoutFrontMatter = removeFrontMatter(from: content)
        return addTitleHeader(to: contentWithoutFrontMatter, title: title)
    }
    
    /// Checks if markdown content already has an H1 header
    /// - Parameter content: The markdown content to check
    /// - Returns: True if content already has an H1 header, false otherwise
    func hasH1Header(in content: String) -> Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmedContent.components(separatedBy: .newlines)
        
        if let firstNonEmptyLine = lines.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return firstNonEmptyLine.hasPrefix("# ")
        }
        
        return false
    }
}