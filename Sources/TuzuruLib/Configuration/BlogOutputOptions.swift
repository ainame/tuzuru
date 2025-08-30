import Foundation

public struct BlogOutputOptions: Sendable {
    /// Output file and directory configuration
    /// Routing style for generated HTML files
    public enum RoutingStyle: String, Sendable, CaseIterable, Codable {
        /// Direct HTML files (e.g., "about.html")
        case direct
        /// Subdirectory with index.html (e.g., "about/index.html" for clean URLs)
        case subdirectory
    }

    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String

    /// Output style for generated pages
    public let routingStyle: RoutingStyle

    public init(directory: String, style: RoutingStyle) {
        self.directory = directory
        self.routingStyle = style
    }

    /// Index page filename is always "index.html"
    public var indexFileName: String {
        "index.html"
    }
}

extension BlogOutputOptions {
    public static let `default` = BlogOutputOptions(directory: "blog", style: .subdirectory)
}

extension BlogOutputOptions: Codable {
    private enum CodingKeys: CodingKey {
        case directory, routingStyle
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.directory = try container.decodeIfPresent(String.self, forKey: .directory) ?? Self.default.directory
        self.routingStyle = try container.decodeIfPresent(BlogOutputOptions.RoutingStyle.self, forKey: .routingStyle) ?? Self.default.routingStyle
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.directory, forKey: .directory)
        try container.encode(self.routingStyle, forKey: .routingStyle)
    }
}
