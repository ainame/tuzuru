import Foundation

public struct BlogInitializer {
    private let fileManager: FileManagerWrapper
    private let bundle: Bundle

    public init(fileManager: FileManagerWrapper, bundle: Bundle? = nil) {
        self.fileManager = fileManager
        self.bundle = bundle ?? Bundle.module
    }

    public func copyTemplateFiles(to templatesDirectory: FilePath) throws {
        try copyBundleDirectory(named: "templates", to: templatesDirectory)
    }

    public func copyAssetFiles(to assetsDirectory: FilePath) throws {
        try copyBundleDirectory(named: "assets", to: assetsDirectory)
    }

    private func copyBundleDirectory(named directoryName: String, to destinationDirectory: FilePath) throws {
        guard let bundleDirectoryPath = bundle.path(forResource: directoryName, ofType: nil) else {
            throw TuzuruError.templateNotFound("\(directoryName) directory")
        }

        try fileManager.copyItem(atPath: FilePath(bundleDirectoryPath), toPath: destinationDirectory)
    }
}
