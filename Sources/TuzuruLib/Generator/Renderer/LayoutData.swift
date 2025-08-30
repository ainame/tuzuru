import Foundation

struct LayoutData<Content: PageRendererable>: PageRendererable {
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let assetsUrl: String
    let currentYear: String
    let years: [String]
    let content: Content
    let partialName: String

    init(
        pageTitle: String,
        blogName: String,
        copyright: String,
        homeUrl: String,
        assetsUrl: String,
        currentYear: String,
        years: [String],
        content: Content
    ) {
        self.pageTitle = pageTitle
        self.blogName = blogName
        self.copyright = copyright
        self.homeUrl = homeUrl
        self.assetsUrl = assetsUrl
        self.currentYear = currentYear
        self.years = years
        self.content = content
        self.partialName = String(describing: type(of: content)).replacingOccurrences(of: "Data", with: "").lowercased()
    }
}
