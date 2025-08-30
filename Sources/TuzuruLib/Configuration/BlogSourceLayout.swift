import Foundation

public struct BlogSourceLayout: Sendable {
    public let templates: BlogTemplates
    public let assets: FilePath
    public let contents: FilePath
    public let imported: FilePath
    public let unlisted: FilePath

    public init(
        templates: BlogTemplates,
        assets: FilePath,
        contents: FilePath,
        imported: FilePath,
        unlisted: FilePath,
    ) {
        self.templates = templates
        self.contents = contents
        self.assets = assets
        self.imported = imported
        self.unlisted = unlisted
    }
}

extension BlogSourceLayout {
    public static let `default` = BlogSourceLayout(
        templates: .default,
        assets: "assets",
        contents: "contents",
        imported: "contents/imported",
        unlisted: "contents/unlisted",
    )
}

extension BlogSourceLayout: Codable {
    private enum CodingKeys: String, CodingKey {
        case templates, assets, contents, imported, unlisted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templates = try container.decodeIfPresent(BlogTemplates.self, forKey: .templates) ?? Self.default.templates
        assets = try FilePath(container.decodeIfPresent(String.self, forKey: .assets) ?? Self.default.assets.string)
        contents = try FilePath(container.decodeIfPresent(String.self, forKey: .contents) ?? Self.default.contents.string)
        imported = try FilePath(container.decodeIfPresent(String.self, forKey: .imported) ?? Self.default.imported.string)
        unlisted = try FilePath(container.decodeIfPresent(String.self, forKey: .unlisted) ?? Self.default.unlisted.string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templates, forKey: .templates)
        try container.encode(assets.string, forKey: .assets)
        try container.encode(contents.string, forKey: .contents)
        try container.encode(imported.string, forKey: .imported)
        try container.encode(unlisted.string, forKey: .unlisted)
    }
}
