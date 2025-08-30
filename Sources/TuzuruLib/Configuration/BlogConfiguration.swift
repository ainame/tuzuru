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
}

extension BlogConfiguration {
    public static let template = BlogConfiguration(
        metadata: BlogMetadata(
            blogName: "My Blog",
            copyright: "2025 My Blog",
            locale: Locale(identifier: "en_GB"),
        ),
        output: BlogOutputOptions(
            directory: "blog",
            style: .subdirectory,
        ),
        sourceLayout: BlogSourceLayout(
            templates: BlogTemplates(
                layout: FilePath("templates/layout.mustache"),
                post: FilePath("templates/post.mustache"),
                list: FilePath("templates/list.mustache"),
            ),
            assets: FilePath("assets"),
            contents: FilePath("contents"),
            imported: FilePath("contents/imported"),
            unlisted: FilePath("contents/unlisted"),
        ),
    )
}
