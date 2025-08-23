import Foundation
import System

public struct Source: Equatable {
    public var title: String
    public var layoutFile: FilePath
    public var pages: [Page]

    public init(title: String, layoutFile: FilePath, pages: [Page]) {
        self.title = title
        self.layoutFile = layoutFile
        self.pages = pages
    }
}