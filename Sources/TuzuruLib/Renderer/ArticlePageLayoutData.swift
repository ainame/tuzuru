import Foundation

struct ArticlePageLayoutData {
    let pageTitle: String
    let blogName: String
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
