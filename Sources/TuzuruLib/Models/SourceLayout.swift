import Foundation
import System

public struct SourceLayout: Sendable {
    public let templates: Templates
    public let contents: FilePath
    public let assets: FilePath

    public init(templates: Templates, contents: FilePath, assets: FilePath) {
        self.templates = templates
        self.contents = contents
        self.assets = assets
    }
}
