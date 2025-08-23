import Foundation
import System

public struct SiteLayout {
    public let root: FilePath
    public let contents: FilePath
    public let assets: FilePath

    public init(root: FilePath, contents: FilePath, assets: FilePath) {
        self.root = root
        self.contents = contents
        self.assets = assets
    }
}