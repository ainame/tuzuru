import Foundation

struct ListData: PageRendererable {
    let articles: [ListItemData]

    func render() -> [String : Any] {
        [
            "articles": articles.map { $0.render() }
        ]
    }
}
