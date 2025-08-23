import Foundation
#if canImport(System)
import System
#else
import SystemPackage
#endif

public struct SourceLayout {
    public let layoutFile: FilePath
    public let contents: FilePath
    public let assets: FilePath

    public init(layoutFile: FilePath, contents: FilePath, assets: FilePath) {
        self.layoutFile = layoutFile
        self.contents = contents
        self.assets = assets
    }
}