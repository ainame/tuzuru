import Foundation
import System

/// Template file configuration
public struct Templates: Sendable, Equatable, Codable {
    public let layoutFile: FilePath
    public let articleFile: FilePath
    public let listFile: FilePath

    public init(layoutFile: FilePath, articleFile: FilePath, listFile: FilePath) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
    
    // Custom Codable implementation for FilePath
    private enum CodingKeys: String, CodingKey {
        case layoutFile, articleFile, listFile
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.layoutFile = FilePath(try container.decode(String.self, forKey: .layoutFile))
        self.articleFile = FilePath(try container.decode(String.self, forKey: .articleFile))
        self.listFile = FilePath(try container.decode(String.self, forKey: .listFile))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(layoutFile.string, forKey: .layoutFile)
        try container.encode(articleFile.string, forKey: .articleFile)
        try container.encode(listFile.string, forKey: .listFile)
    }
}
