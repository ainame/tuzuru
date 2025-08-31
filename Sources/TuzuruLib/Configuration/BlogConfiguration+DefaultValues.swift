import Foundation

extension BlogConfiguration {
    public static let `default` = BlogConfiguration(
        metadata: BlogMetadata(
            blogName: "My Blog",
            copyright: "My Blog",
            locale: Locale(identifier: "en_GB"),
        ),
        output: .default,
        sourceLayout: .default,
    )
}

extension BlogOutputOptions {
    public static let `default` = BlogOutputOptions(
        directory: "blog",
        routingStyle: .subdirectory,
        homePageStyle: .pastYear
    )
}

extension BlogSourceLayout {
    public static let `default` = BlogSourceLayout(
        templates: .default,
        assets: "assets",
        contents: "contents",
        imported: "contents/imported",
        unlisted: "contents/unlisted",
    )
}

extension BlogTemplates {
    public static let `default`: BlogTemplates = .init(
        layout: "templates/layout.mustache",
        post: "templates/post.mustache",
        list: "templates/list.mustache"
    )
}
