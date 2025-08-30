import Foundation

/// Configuration for blog generation, eliminating hardcoded assumptions
public struct BlogConfiguration: Sendable, Codable {
    /// Blog metadata
    public let metadata: BlogMetadata

    /// Output configuration
    public let output: BlogOutputOptions

    /// Source file directory paths
    public let sourceLayout: BlogSourceLayout

    public init(
        metadata: BlogMetadata,
        output: BlogOutputOptions,
        sourceLayout: BlogSourceLayout,
    ) {
        self.metadata = metadata
        self.output = output
        self.sourceLayout = sourceLayout
    }

    private enum CodingKeys: CodingKey {
        case metadata, output, sourceLayout
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metadata = try container.decode(BlogMetadata.self, forKey: .metadata)
        self.output = try container.decodeIfPresent(BlogOutputOptions.self, forKey: .output) ?? BlogOutputOptions.default
        self.sourceLayout = try container.decodeIfPresent(BlogSourceLayout.self, forKey: .sourceLayout) ?? BlogSourceLayout.default
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.metadata, forKey: .metadata)
        try container.encode(self.output, forKey: .output)
        try container.encode(self.sourceLayout, forKey: .sourceLayout)
    }
}

extension BlogConfiguration {
    public static let template = BlogConfiguration(
        metadata: BlogMetadata(
            blogName: "My Blog",
            copyright: "My Blog",
            locale: Locale(identifier: "en_GB"),
        ),
        output: .default,
        sourceLayout: .default,
    )
}
