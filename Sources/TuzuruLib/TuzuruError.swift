import Foundation

public enum TuzuruError: Error {
    case templateNotFound(String)
    case directoryCreationFailed(String)
    case fileNotFound(String)
}