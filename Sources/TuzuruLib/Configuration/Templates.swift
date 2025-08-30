import Foundation

/// Template file configuration
public struct Templates: Sendable, Equatable, Codable {
    public let layout: FilePath
    public let post: FilePath
    public let list: FilePath

    public init(layoutFile: FilePath, postFile: FilePath, listFile: FilePath) {
        self.layout = layoutFile
        self.post = postFile
        self.list = listFile
    }

    // Custom Codable implementation for FilePath
    private enum CodingKeys: String, CodingKey {
        case layout, post, list
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layout = try FilePath(container.decode(String.self, forKey: .layout))
        post = try FilePath(container.decode(String.self, forKey: .post))
        list = try FilePath(container.decode(String.self, forKey: .list))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layout.string, forKey: .layout)
        try container.encode(post.string, forKey: .post)
        try container.encode(list.string, forKey: .list)
    }
}
