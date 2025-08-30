import Foundation

struct LayoutData<Content: PageRendererable>: PageRendererable {
    let content: Content
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let assetsUrl: String
    let currentYear: String
    let years: [String]
    let categories: [String]
    let buildVersion: String
    let partialName: String

    init(
        content: Content,
        pageTitle: String,
        blogName: String,
        copyright: String,
        homeUrl: String,
        assetsUrl: String,
        currentYear: String,
        years: [String],
        categories: [String],
        buildVersion: String,
    ) {
        self.content = content
        self.pageTitle = pageTitle
        self.blogName = blogName
        self.copyright = copyright
        self.homeUrl = homeUrl
        self.assetsUrl = assetsUrl
        self.currentYear = currentYear
        self.years = years
        self.categories = categories
        self.buildVersion = buildVersion
        self.partialName = String(describing: type(of: content)).replacingOccurrences(of: "Data", with: "").lowercased()
    }
}
