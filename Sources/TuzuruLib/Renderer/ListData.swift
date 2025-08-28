import Foundation

struct ListData: PageRendererable {
    let title: String
    let articles: [ListItemData]

    func render() -> [String : Any] {
        [
            "title": title,
            "articles": articles.map { $0.render() },
        ]
    }
}
