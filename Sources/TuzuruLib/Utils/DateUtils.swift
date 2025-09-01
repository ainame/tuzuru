import Foundation

/// Utility for parsing date strings from various formats supported by Hugo and Jekyll
struct DateUtils: Sendable {
    /// Parses date string from various formats supported by Hugo and Jekyll
    /// - Parameter dateString: The date string from YAML front matter
    /// - Returns: Date object if parsing succeeds
    static func parseDate(_ dateString: String) -> Date? {
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
    
    private static func createFormatter(format: String, locale: String = "en_US_POSIX") -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: locale)
        formatter.timeZone = TimeZone(secondsFromGMT: 0) // Default to UTC as per Hugo docs
        return formatter
    }
}