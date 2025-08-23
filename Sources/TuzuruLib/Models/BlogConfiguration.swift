import Foundation
import System

/// Configuration for blog generation, eliminating hardcoded assumptions
public struct BlogConfiguration: Sendable {
    /// Template file paths
    public let templates: TemplateConfiguration
    
    /// Output configuration
    public let output: OutputConfiguration
    
    /// Blog metadata
    public let metadata: BlogMetadata
    
    public init(
        templates: TemplateConfiguration = TemplateConfiguration(),
        output: OutputConfiguration = OutputConfiguration(),
        metadata: BlogMetadata = BlogMetadata()
    ) {
        self.templates = templates
        self.output = output
        self.metadata = metadata
    }
}
