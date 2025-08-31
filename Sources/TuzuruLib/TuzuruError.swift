import Foundation

public enum TuzuruError: LocalizedError {
    case templateNotFound(String)
    case directoryCreationFailed(String)
    case fileNotFound(String)
    case yearDirectoryConflict(String)
    case configurationAlreadyExists

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let name):
            return "Template not found: \(name)"
        case .directoryCreationFailed(let path):
            return "Failed to create directory: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .yearDirectoryConflict(let path):
            return "Year directory conflict: \(path)"
        case .configurationAlreadyExists:
            return "tuzuru.json already exists. Aborting initialization."
        }
    }
}
