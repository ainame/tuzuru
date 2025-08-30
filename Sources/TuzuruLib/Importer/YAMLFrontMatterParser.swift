import Foundation
import Yams

/// Parser for extracting YAML front matter from markdown files
struct YAMLFrontMatterParser: Sendable {
    struct FrontMatterMetadata: Codable, Sendable {
        let title: String?
        let date: String?
        let author: String?
        let draft: Bool?
        let type: String?
        
        private enum CodingKeys: String, CodingKey {
            case title, date, author, draft, type
        }
    }
    
    struct ParseResult: Sendable {
        let metadata: FrontMatterMetadata
        let content: String
    }
    
    /// Parses YAML front matter from markdown content
    /// - Parameter markdownContent: The raw markdown content with potential YAML front matter
    /// - Returns: ParseResult containing metadata and cleaned content
    /// - Throws: YAMLFrontMatterError if parsing fails
    func parse(_ markdownContent: String) throws -> ParseResult {
        let lines = markdownContent.components(separatedBy: .newlines)
        
        // Check if content starts with YAML front matter delimiter
        guard lines.first == "---" else {
            // No front matter, return empty metadata and original content
            let metadata = FrontMatterMetadata(title: nil, date: nil, author: nil, draft: nil, type: nil)
            return ParseResult(metadata: metadata, content: markdownContent)
        }
        
        // Find the closing delimiter
        var frontMatterLines: [String] = []
        var contentStartIndex = 1
        var foundClosingDelimiter = false
        
        for i in 1..<lines.count {
            if lines[i] == "---" {
                foundClosingDelimiter = true
                contentStartIndex = i + 1
                break
            }
            frontMatterLines.append(lines[i])
        }
        
        guard foundClosingDelimiter else {
            throw YAMLFrontMatterError.missingClosingDelimiter
        }
        
        // Parse YAML
        let yamlString = frontMatterLines.joined(separator: "\n")
        let metadata: FrontMatterMetadata
        
        do {
            metadata = try YAMLDecoder().decode(FrontMatterMetadata.self, from: yamlString)
        } catch {
            throw YAMLFrontMatterError.invalidYAML(error.localizedDescription)
        }
        
        // Extract remaining content
        let contentLines = Array(lines[contentStartIndex...])
        let cleanContent = contentLines.joined(separator: "\n")
        
        return ParseResult(metadata: metadata, content: cleanContent)
    }
    
    /// Parses date string from various formats supported by Hugo and Jekyll
    /// - Parameter dateString: The date string from YAML front matter
    /// - Returns: Date object if parsing succeeds
    func parseDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            // Hugo formats with timezone offset
            createFormatter(format: "yyyy-MM-dd'T'HH:mm:ssXXXXX"), // 2023-10-15T13:18:50-07:00
            createFormatter(format: "yyyy-MM-dd'T'HH:mm:ssxx"),    // 2023-10-15T13:18:50-0700
            // Hugo/ISO 8601 UTC formats
            createFormatter(format: "yyyy-MM-dd'T'HH:mm:ssZ"),     // 2023-10-15T13:18:50Z
            createFormatter(format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ"), // With milliseconds
            createFormatter(format: "yyyy-MM-dd'T'HH:mm:ss"),      // 2023-10-15T13:18:50 (no timezone, defaults to UTC)
            // Jekyll formats with timezone offset
            createFormatter(format: "yyyy-MM-dd HH:mm:ss XXXXX"),  // 2025-06-05 08:31:19 +07:00
            createFormatter(format: "yyyy-MM-dd HH:mm:ss xx"),     // 2025-06-05 08:31:19 +0700
            createFormatter(format: "yyyy-MM-dd HH:mm:ss Z"),      // Alternative timezone format
            createFormatter(format: "yyyy-MM-dd HH:mm:ss"),        // 2025-06-05 08:31:19 (no timezone)
            // Date-only formats (Hugo and Jekyll)
            createFormatter(format: "yyyy-MM-dd"),                 // 2025-06-05
            // Hugo alternative format
            createFormatter(format: "dd MMM yyyy", locale: "en_US"), // 15 Oct 2023
            // Legacy formats for compatibility
            createFormatter(format: "dd/MM/yyyy"),
            createFormatter(format: "MM/dd/yyyy"),
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    private func createFormatter(format: String, locale: String = "en_US_POSIX") -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: locale)
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Default to UTC as per Hugo docs
        return formatter
    }
}

enum YAMLFrontMatterError: Error, LocalizedError, Sendable, Equatable {
    case missingClosingDelimiter
    case invalidYAML(String)
    case missingRequiredField(String)
    
    static func == (lhs: YAMLFrontMatterError, rhs: YAMLFrontMatterError) -> Bool {
        switch (lhs, rhs) {
        case (.missingClosingDelimiter, .missingClosingDelimiter):
            return true
        case (.invalidYAML(let lhsMsg), .invalidYAML(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.missingRequiredField(let lhsField), .missingRequiredField(let rhsField)):
            return lhsField == rhsField
        default:
            return false
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .missingClosingDelimiter:
            return "Missing closing '---' delimiter for YAML front matter"
        case .invalidYAML(let error):
            return "Invalid YAML format: \(error)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        }
    }
}