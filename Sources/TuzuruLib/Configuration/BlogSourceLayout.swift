import Foundation

public struct BlogSourceLayout: Sendable, Codable {
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

    private enum CodingKeys: String, CodingKey {
        case templates, assets, contents, imported, unlisted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templates = try container.decode(BlogTemplates.self, forKey: .templates)
        assets = try FilePath(container.decodeIfPresent(String.self, forKey: .assets) ?? "assets")
        contents = try FilePath(container.decodeIfPresent(String.self, forKey: .contents) ?? "contents")
        imported = try FilePath(container.decodeIfPresent(String.self, forKey: .imported) ?? "contents/imported")
        unlisted = try FilePath(container.decodeIfPresent(String.self, forKey: .unlisted) ?? "contents/unlisted")
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
