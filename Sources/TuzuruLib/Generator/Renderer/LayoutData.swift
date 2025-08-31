import Foundation

struct LayoutData<Content: PageRendererable>: PageRendererable {
    let content: Content
    let pageTitle: String
    let blogName: String
    let copyright: String
    let homeUrl: String
    let assetsUrl: String
    let currentYear: String
    let hasYears: Bool
    let years: [String]
    let hasCategories: Bool
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
        hasYears: Bool,
        years: [String],
        hasCategories: Bool,
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
        self.hasYears = hasYears
        self.years = years
        self.hasCategories = hasCategories
        self.categories = categories
        self.buildVersion = buildVersion
        self.partialName = String(describing: type(of: content)).replacingOccurrences(of: "Data", with: "").lowercased()
    }
}
