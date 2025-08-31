import Foundation

/// Site metadata configuration
public struct BlogMetadata: Sendable, Codable {
    /// Blog title displayed in layouts
    public let blogName: String

    /// Copyright notice
    public let copyright: String

    /// Blog description for SEO meta tag
    public let description: String

    /// Base URL for the blog (e.g., "https://example.com")
    public let baseUrl: String

    /// Locale for date formatting
    public let locale: Locale

    public init(
        blogName: String,
        copyright: String,
        description: String,
        baseUrl: String,
        locale: Locale,
    ) {
        self.blogName = blogName
        self.copyright = copyright
        self.description = description
        self.baseUrl = baseUrl
        self.locale = locale
    }

    // Custom Codable implementation for Locale
    private enum CodingKeys: String, CodingKey {
        case blogName, copyright, description, baseUrl, locale
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.blogName = try container.decode(String.self, forKey: .blogName)
        self.copyright = try container.decode(String.self, forKey: .copyright)
        self.description = try container.decode(String.self, forKey: .description)
        self.baseUrl = try container.decode(String.self, forKey: .baseUrl)
        let localeIdentifier = try container.decode(String.self, forKey: .locale)
        self.locale = Locale(identifier: localeIdentifier)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blogName, forKey: .blogName)
        try container.encode(copyright, forKey: .copyright)
        try container.encode(description, forKey: .description)
        try container.encode(baseUrl, forKey: .baseUrl)
        try container.encode(locale.identifier, forKey: .locale)
    }
}
