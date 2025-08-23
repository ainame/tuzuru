import Foundation
import System

public struct Source: Equatable {
    public var title: String
    public var layoutFile: FilePath
    public var pages: [Article]

    public init(title: String, layoutFile: FilePath, pages: [Article]) {
        self.title = title
        self.layoutFile = layoutFile
        self.pages = pages
    }
}