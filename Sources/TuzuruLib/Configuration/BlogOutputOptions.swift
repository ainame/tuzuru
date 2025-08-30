import Foundation

public struct BlogOutputOptions: Sendable {
    /// Output directory name (e.g., "blog", "site", "build", "dist")
    public let directory: String

    /// Output style for generated pages
    public let routingStyle: RoutingStyle

    public let homePageStyle: HomePageStyle

    public init(
        directory: String,
        routingStyle: RoutingStyle,
        homePageStyle: HomePageStyle
    ) {
        self.directory = directory
        self.routingStyle = routingStyle
        self.homePageStyle = homePageStyle
    }

    /// Index page filename is always "index.html"
    public var indexFileName: String {
        "index.html"
    }
}

extension BlogOutputOptions {
    /// Output file and directory configuration
    /// Routing style for generated HTML files
    public enum RoutingStyle: String, Sendable, CaseIterable, Codable {
        /// Direct HTML files (e.g., "about.html")
        case direct
        /// Subdirectory with index.html (e.g., "about/index.html" for clean URLs)
        case subdirectory
    }

    public enum HomePageStyle: Sendable, Codable {
        case all
        case currentYear
        case last(Int)

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            switch value {
            case "all":
                self = .all
            case "currentYear":
                self = .currentYear
            default:
                if let intValue = Int(value) {
                    self = .last(intValue)
                    return
                }
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid HomePageStyle value: \(value). [\"all\", \"currentYear\", a number in String (last X posts)] are available."
                )
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .all:
                try container.encode("all")
            case .currentYear:
                try container.encode("currentYear")
            case .last(let intValue):
                try container.encode(String(intValue))
            }
        }
    }
}

extension BlogOutputOptions: Codable {
    private enum CodingKeys: CodingKey {
        case directory, routingStyle, homePageStyle
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.directory = try container.decodeIfPresent(String.self, forKey: .directory) ?? Self.default.directory
        self.routingStyle = try container.decodeIfPresent(RoutingStyle.self, forKey: .routingStyle) ?? Self.default.routingStyle
        self.homePageStyle = try container.decodeIfPresent(HomePageStyle.self, forKey: .homePageStyle) ?? Self.default.homePageStyle
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.directory, forKey: .directory)
        try container.encode(self.routingStyle, forKey: .routingStyle)
        try container.encode(self.homePageStyle, forKey: .homePageStyle)
    }
}
