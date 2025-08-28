import Foundation

struct PostData: PageRendererable {
    let title: String
    let author: String
    let publishedAt: String
    let body: String
    
    func render() -> [String: Any] {
        [
            "title": title,
            "author": author,
            "publishedAt": publishedAt,
            "body": body,
        ]
    }
}
