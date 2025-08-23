import Foundation
import System

/// Template file configuration
public struct Templates: Sendable, Equatable {
    public let layoutFile: FilePath
    public let articleFile: FilePath
    public let listFile: FilePath

    public init(layoutFile: FilePath, articleFile: FilePath, listFile: FilePath) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
}
