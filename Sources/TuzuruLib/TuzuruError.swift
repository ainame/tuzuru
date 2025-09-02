import Foundation

public enum TuzuruError: LocalizedError {
    case templateNotFound(String)
    case directoryCreationFailed(String)
    case fileNotFound(String)
    case titleNotFound(String)
    case yearDirectoryConflict(String)
    case configurationAlreadyExists
    case invalidDateFormat(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template not found: \(name)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .titleNotFound(let message):
            return "Title not found: \(message)"
        case .yearDirectoryConflict(let path):
            return "Year directory conflict: \(path)"
        case .configurationAlreadyExists:
            return "tuzuru.json already exists. Aborting initialization."
        case .invalidDateFormat(let dateString):
            return "Invalid date format: '\(dateString)'. Supported formats include: '2023-12-01', '2023-12-01 10:30:00', '2023-12-01T10:30:00Z', '2023-12-01 10:30:00 +0900'"
        }
    }
}
