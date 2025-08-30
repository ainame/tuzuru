import Foundation

/// Configuration for blog generation, eliminating hardcoded assumptions
public struct BlogConfiguration: Sendable, Codable {
    /// Source file directory paths
    public let sourceLayout: BlogSourceLayout

    /// Output configuration
    public let output: BlogOutputOptions

    /// Blog metadata
    public let metadata: BlogMetadata

    public init(
        sourceLayout: BlogSourceLayout,
        output: BlogOutputOptions,
        metadata: BlogMetadata,
    ) {
        self.sourceLayout = sourceLayout
        self.output = output
        self.metadata = metadata
    }
}
