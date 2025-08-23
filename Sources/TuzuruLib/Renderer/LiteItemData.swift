import Foundation

struct ListItemData {
    let title: String
    let author: String
    let publishedAt: String
    let excerpt: String
    let url: String

    func render() -> [String: Any] {
        [
            "title": title,
            "author": author,
            "publishedAt": publishedAt,
            "url": url,
            "excerpt": excerpt,
        ]
    }
}
