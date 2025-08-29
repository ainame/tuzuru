import Foundation
import System

public struct SourceLayout: Sendable, Codable {
    public let templates: Templates
    public let contents: FilePath
    public let unlisted: FilePath
    public let assets: FilePath

    public init(templates: Templates, contents: FilePath, unlisted: FilePath, assets: FilePath) {
        self.templates = templates
        self.contents = contents
        self.unlisted = unlisted
        self.assets = assets
    }

    // Custom Codable implementation for FilePath
    private enum CodingKeys: String, CodingKey {
        case templates, contents, unlisted, assets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        templates = try container.decode(Templates.self, forKey: .templates)
        contents = try FilePath(container.decode(String.self, forKey: .contents))
        unlisted = try FilePath(container.decodeIfPresent(String.self, forKey: .unlisted) ?? "contents/unlisted")
        assets = try FilePath(container.decode(String.self, forKey: .assets))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templates, forKey: .templates)
        try container.encode(contents.string, forKey: .contents)
        try container.encode(unlisted.string, forKey: .unlisted)
        try container.encode(assets.string, forKey: .assets)
    }
}
