import Foundation

struct ListPageLayoutData {
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let content: String

    func render() -> [String: Any] {
        [
            "pageTitle": pageTitle,
            "blogName": blogName,
            "homeUrl": homeUrl,
            "content": content,
        ]
    }
}
