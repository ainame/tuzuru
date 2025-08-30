import Foundation

/// Site metadata configuration
public struct BlogMetadata: Sendable, Codable {
    /// Blog title displayed in layouts
    public let blogName: String

    /// Copyright notice
    public let copyright: String
    
    /// Locale for date formatting
    public let locale: Locale

    public init(
        blogName: String,
        copyright: String,
        locale: Locale = Locale(identifier: "en_US")
    ) {
        self.blogName = blogName
        self.copyright = copyright
        self.locale = locale
    }
    
    // Custom Codable implementation for Locale
    private enum CodingKeys: String, CodingKey {
        case blogName, copyright, locale
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.blogName = try container.decode(String.self, forKey: .blogName)
        self.copyright = try container.decode(String.self, forKey: .copyright)
        let localeIdentifier = try container.decode(String.self, forKey: .locale)
        self.locale = Locale(identifier: localeIdentifier)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(blogName, forKey: .blogName)
        try container.encode(copyright, forKey: .copyright)
        try container.encode(locale.identifier, forKey: .locale)
    }
}
