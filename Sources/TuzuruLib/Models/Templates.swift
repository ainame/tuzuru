import Foundation

/// Template file configuration
public struct Templates: Sendable, Equatable, Codable {
    public let layoutFile: FilePath
    public let postFile: FilePath
    public let listFile: FilePath

    public init(layoutFile: FilePath, postFile: FilePath, listFile: FilePath) {
        self.layoutFile = layoutFile
        self.postFile = postFile
        self.listFile = listFile
    }

    // Custom Codable implementation for FilePath
    private enum CodingKeys: String, CodingKey {
        case layoutFile, postFile, listFile
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        layoutFile = try FilePath(container.decode(String.self, forKey: .layoutFile))
        postFile = try FilePath(container.decode(String.self, forKey: .postFile))
        listFile = try FilePath(container.decode(String.self, forKey: .listFile))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layoutFile.string, forKey: .layoutFile)
        try container.encode(postFile.string, forKey: .postFile)
        try container.encode(listFile.string, forKey: .listFile)
    }
}
