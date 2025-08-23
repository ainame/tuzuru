import Foundation
#if canImport(System)
import System
#else
import SystemPackage
#endif

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