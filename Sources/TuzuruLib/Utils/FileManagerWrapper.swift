import Foundation

/// FileManagerWrapper benefits several points -
///
/// * FilePath as currency type
/// * Working directory concept per instance for parallaized-testing (FileManager.currentDirectoryPath is managed per "process")
/// * No thread-safe calls are leaked so that AI won't use them by default
/// * Sendable support (though it's unchecked)
/// * Hide use of "ObjCBool" in fileExists
///
/// Don't use FileManager.currentDirectoryPath or FileManager.changeCurrentDirectory in this file.
///
/// Quote on thread-safety in FileManager
/// > The methods of the shared FileManager object can be called from multiple threads safely.
/// > However, if you use a delegate to receive notifications about the status of move, copy, remove,
/// > and link operations, you should create a unique instance of the file manager object,
/// > assign your delegate to that object, and use that file manager to initiate your operations.
/// https://developer.apple.com/documentation/Foundation/FileManager
public struct FileManagerWrapper: @unchecked Sendable {
    public let workingDirectory: FilePath
    private let fileManager: FileManager

    /// workingDirectory parameter needs to be app's very
    ///
    /// - Parameters:
    ///   - workingDirectory: workingDirectory that can be used as FileManager.default.currentDirectoryPath in parallel testing
    ///   - fileManager: Different FileManager instance can be injected here in testing
    public init(workingDirectory: FilePath, fileManager: FileManager = .default) {
        self.workingDirectory = workingDirectory
        self.fileManager = fileManager
    }

    public init(workingDirectory: String, fileManager: FileManager = .default) {
        self.init(workingDirectory: FilePath(workingDirectory), fileManager: fileManager)
    }

    public func fileExists(atPath path: FilePath) -> Bool {
        fileManager.fileExists(atPath: normalizePath(path))
    }

    public func fileExists(atPath path: FilePath, isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
        var objcBool = ObjCBool(isDirectory?.pointee ?? false)
        let result = fileManager.fileExists(atPath: normalizePath(path), isDirectory: &objcBool)
        isDirectory?.pointee = objcBool.boolValue
        return result
    }

    public func createFile(
        atPath path: FilePath,
        contents: Data?,
        attributes: [FileAttributeKey : Any]? = nil,
    ) -> Bool {
        fileManager.createFile(
            atPath: normalizePath(path),
            contents: contents,
            attributes: attributes
        )
    }

    public func createDirectory(
        atPath path: FilePath,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey : Any]? = nil,
    ) throws {
        try fileManager.createDirectory(
            atPath: normalizePath(path),
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }

    public func contents(atPath path: FilePath) -> Data? {
        fileManager.contents(atPath: normalizePath(path))
    }

    public func copyItem(atPath srcPath: FilePath, toPath dstPath: FilePath) throws {
        try fileManager.copyItem(atPath: normalizePath(srcPath), toPath: normalizePath(dstPath))
    }

    public func removeItem(atPath path: FilePath) throws {
        try fileManager.removeItem(atPath: normalizePath(path))
    }

    public func enumerator(atPath path: FilePath) -> FileManager.DirectoryEnumerator? {
        fileManager.enumerator(atPath: normalizePath(path))
    }

    public func contentsOfDirectory(atPath path: FilePath) throws -> [FilePath] {
        try fileManager.contentsOfDirectory(atPath: normalizePath(path)).map { FilePath($0) }
    }

    private func normalizePath(_ path: FilePath) -> String {
        // expected workingDirectory can be different from FileManager.currentDirectoryPath,
        // when running unit tests using file resources in parallel. It has to isolate each other test case
        // but currentDirectoryPath is managed per "process".
        if fileManager.currentDirectoryPath != workingDirectory.string {
            workingDirectory.appending(path.string).string
        } else {
            path.string
        }
    }
}
