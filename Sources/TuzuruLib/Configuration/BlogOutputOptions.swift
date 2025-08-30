import Foundation

public struct BlogOutputOptions: Sendable, Codable {
    /// Output file and directory configuration
    /// Output style for generated HTML files
    public enum OutputStyle: String, Sendable, CaseIterable, Codable {
        /// Direct HTML files (e.g., "about.html")
        case direct
        /// Subdirectory with index.html (e.g., "about/index.html" for clean URLs)
        case subdirectory
    }

    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String

    /// Output style for generated pages
    public let style: OutputStyle

    public init(directory: String, style: OutputStyle) {
        self.directory = directory
        self.style = style
    }

    /// Index page filename is always "index.html"
    public var indexFileName: String {
        "index.html"
    }

    private enum CodingKeys: CodingKey {
        case directory, style
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.directory = try container.decodeIfPresent(String.self, forKey: .directory) ?? "blog"
        self.style = try container.decodeIfPresent(BlogOutputOptions.OutputStyle.self, forKey: .style) ?? .subdirectory
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.directory, forKey: .directory)
        try container.encode(self.style, forKey: .style)
    }
}
