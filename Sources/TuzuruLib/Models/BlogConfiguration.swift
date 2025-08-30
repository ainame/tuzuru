import Foundation

/// Configuration for blog generation, eliminating hardcoded assumptions
public struct BlogConfiguration: Sendable, Codable {
    /// Source file directory paths
    public let sourceLayout: SourceLayout

    /// Output configuration
    public let outputOptions: OutputOptions

    /// Blog metadata
    public let metadata: BlogMetadata

    public init(
        sourceLayout: SourceLayout,
        output: OutputOptions,
        metadata: BlogMetadata,
    ) {
        self.sourceLayout = sourceLayout
        outputOptions = output
        self.metadata = metadata
    }
}
