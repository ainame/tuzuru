import Foundation

struct ListData: PageRendererable {
    let title: String
    let posts: [ListItemData]

    func render() -> [String : Any] {
        [
            "title": title,
            "posts": posts.map { $0.render() },
        ]
    }
}
