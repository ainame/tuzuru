import Foundation
import System

struct SourceLayout: Sendable {
    let templates: FilePath
    let contents: FilePath
    let assets: FilePath

    init(templates: FilePath, contents: FilePath, assets: FilePath) {
        self.templates = templates
        self.contents = contents
        self.assets = assets
    }
}
