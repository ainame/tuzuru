import Foundation
import System

/// Configuration for blog generation, eliminating hardcoded assumptions
public struct BlogConfiguration: Sendable {
    /// Source file directory paths
    public let sourceLayout: SourceLayout

    /// Template file paths
    public let templates: Templates
    
    /// Output configuration
    public let outputOptions: OutputOptions
    
    /// Blog metadata
    public let metadata: BlogMetadata
    
    public init(
        sourceLayout: SourceLayout,
        templates: Templates,
        output: OutputOptions,
        metadata: BlogMetadata,
    ) {
        self.sourceLayout = sourceLayout
        self.templates = templates
        self.outputOptions = output
        self.metadata = metadata
    }
}
