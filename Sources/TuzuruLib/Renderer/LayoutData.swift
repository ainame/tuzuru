import Foundation

struct LayoutData {
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let content: String

    func render() -> [String: Any] {
        [
            "pageTitle": pageTitle,
            "blogName": blogName,
            "copyright": copyright,
            "homeUrl": homeUrl,
            "content": content,
        ]
    }
}
