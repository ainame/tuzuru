import Foundation

/// Template file configuration
public struct BlogTemplates: Sendable {
    public let layout: FilePath
    public let post: FilePath
    public let list: FilePath

    public init(layout: FilePath, post: FilePath, list: FilePath) {
        self.layout = layout
        self.post = post
        self.list = list
    }
}

extension BlogTemplates {
    public static let `default`: BlogTemplates = .init(
        layout: "templates/layout.mustache",
        post: "templates/post.mustache",
        list: "templates/list.mustache"
    )
}

extension BlogTemplates: Codable {
    // Custom Codable implementation for FilePath
    private enum CodingKeys: String, CodingKey {
        case layout, post, list
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layout = try FilePath(container.decodeIfPresent(String.self, forKey: .layout) ?? Self.default.layout.string)
        post = try FilePath(container.decodeIfPresent(String.self, forKey: .post) ?? Self.default.post.string)
        list = try FilePath(container.decodeIfPresent(String.self, forKey: .list) ?? Self.default.list.string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layout.string, forKey: .layout)
        try container.encode(post.string, forKey: .post)
        try container.encode(list.string, forKey: .list)
    }
}
