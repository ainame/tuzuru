import Foundation

struct LayoutData<Content: PageRendererable>: PageRendererable {
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let assetsUrl: String
    let content: Content

    func render() -> [String: Any] {
        let partialName = String(describing: type(of: content)).replacingOccurrences(of: "Data", with: "").lowercased()
        return [
            "pageTitle": pageTitle,
            "blogName": blogName,
            "copyright": copyright,
            "homeUrl": homeUrl,
            "assetsUrl": assetsUrl,
            "content": content.render(),
            "partialName": partialName,
        ]
    }
}
