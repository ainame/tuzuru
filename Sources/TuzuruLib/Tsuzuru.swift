import Foundation
import SystemPackage

public struct Tuzuru {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func loadSources(_ sourceLayout: SourceLayout) throws -> Source {
        var source = Source(title: "", layoutFile: sourceLayout.layoutFile, pages: [])

        let filePaths = try fileManager.contentsOfDirectory(atPath: sourceLayout.contents.string)
        for filePath in filePaths {
            let page = Page(
                path: FilePath(filePath),
                title: "title",
                author: "ainame",
                publishedAt: Date(),
            )
            source.pages.append(page)
        }

        return source
    }

    public func generate(_ source: Source) -> SiteLayout {
        SiteLayout(
            root: FilePath(""),
            contents: FilePath(""),
            assets: FilePath("")
        )
    }
}

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

public struct Page: Hashable {
    public let path: FilePath
    public var title: String
    public var author: String
    public var publishedAt: Date

    public init(path: FilePath, title: String, author: String, publishedAt: Date) {
        self.path = path
        self.title = title
        self.author = author
        self.publishedAt = publishedAt
    }
}
