import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

public struct SitemapGenerator: Sendable {
    private let pathGenerator: PathGenerator
    private let baseUrl: String
    private let fileManager: FileManagerWrapper

    public init(pathGenerator: PathGenerator, baseUrl: String, fileManager: FileManagerWrapper) {
        self.pathGenerator = pathGenerator
        self.baseUrl = baseUrl
        self.fileManager = fileManager
    }

    /// Generate sitemap.xml content from Source data
    public func generateSitemap(from source: Source) throws -> String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Create root urlset element
        let urlsetElement = XMLElement(name: "urlset")
        urlsetElement.addAttribute(XMLNode.attribute(withName: "xmlns", stringValue: "http://www.sitemaps.org/schemas/sitemap/0.9") as! XMLNode)

        // Add home page
        let homeUrl = pathGenerator.generateAbsoluteUrl(baseUrl: baseUrl, relativePath: "")
        let homeUrlElement = createUrlElement(
            loc: homeUrl,
            lastmod: nil,
            changefreq: "weekly",
            priority: "1.0"
        )
        urlsetElement.addChild(homeUrlElement)

        // Add individual posts (both listed and unlisted for SEO)
        let sortedPosts = source.posts.sorted { $0.publishedAt > $1.publishedAt }
        for post in sortedPosts {
            let relativeUrl = pathGenerator.generateUrl(for: post.path, isUnlisted: post.isUnlisted)
            let absoluteUrl = pathGenerator.generateAbsoluteUrl(baseUrl: baseUrl, relativePath: relativeUrl)
            let lastmod = dateFormatter.string(from: post.publishedAt)
            let priority = post.isUnlisted ? "0.5" : "0.8"

            let urlElement = createUrlElement(
                loc: absoluteUrl,
                lastmod: lastmod,
                changefreq: "monthly",
                priority: priority
            )
            urlsetElement.addChild(urlElement)
        }

        // Add yearly list pages (only if there are listed posts)
        let listedPosts = source.posts.filter { !$0.isUnlisted }
        if !listedPosts.isEmpty {
            for year in source.years {
                let yearUrl = pathGenerator.generateAbsoluteUrl(baseUrl: baseUrl, relativePath: "\(year)/")
                let urlElement = createUrlElement(
                    loc: yearUrl,
                    lastmod: nil,
                    changefreq: "monthly",
                    priority: "0.6"
                )
                urlsetElement.addChild(urlElement)
            }
        }

        // Add directory list pages for non-imported directories with listed posts
        let directoryUrls = getDirectoryUrls(from: listedPosts, source: source)
        for directoryUrl in directoryUrls {
            let absoluteUrl = pathGenerator.generateAbsoluteUrl(baseUrl: baseUrl, relativePath: directoryUrl)
            let urlElement = createUrlElement(
                loc: absoluteUrl,
                lastmod: nil,
                changefreq: "monthly",
                priority: "0.6"
            )
            urlsetElement.addChild(urlElement)
        }

        // Create XML document
        let xmlDocument = XMLDocument(rootElement: urlsetElement)
        xmlDocument.version = "1.0"
        xmlDocument.characterEncoding = "UTF-8"

        let xmlData = xmlDocument.xmlData(options: [.nodePrettyPrint])
        return String(data: xmlData, encoding: .utf8) ?? ""
    }

    /// Generate and save sitemap.xml to the blog directory
    public func generateAndSave(from source: Source, to blogRoot: FilePath) throws {
        let sitemapXml = try generateSitemap(from: source)
        let sitemapPath = blogRoot.appending("sitemap.xml")

        let sitemapData = Data(sitemapXml.utf8)
        _ = fileManager.createFile(atPath: sitemapPath, contents: sitemapData)
    }

    /// Extract directory URLs that would have list pages generated
    /// (This mirrors the logic in BlogGenerator.generateDirectoryListPages)
    private func getDirectoryUrls(from posts: [Post], source: Source) -> [String] {
        // This logic mirrors BlogGenerator.generateDirectoryListPages
        var directories: Set<String> = []

        // We need to get the contents base path - let's assume it from configuration
        // Since we don't have direct access to configuration here, we'll extract from posts
        for post in posts where !post.isUnlisted {
            let postPathComponents = post.path.components

            // Find posts that are in subdirectories (not root level)
            if postPathComponents.count > 1 {
                // Get the directory part by removing the filename
                let directoryComponents = Array(postPathComponents.dropLast())
                if directoryComponents.count > 0 {
                    // Get the top-level directory name
                    let topLevelDir = directoryComponents.last?.string ?? ""

                    // Skip empty directories and imported directory
                    if !topLevelDir.isEmpty && topLevelDir != "imported" {
                        directories.insert("\(topLevelDir)/")
                    }
                }
            }
        }

        return Array(directories).sorted()
    }

    /// Create a URL element for sitemap with proper XML structure
    private func createUrlElement(loc: String, lastmod: String?, changefreq: String, priority: String) -> XMLElement {
        let urlElement = XMLElement(name: "url")

        // Add location (required)
        let locElement = XMLElement(name: "loc", stringValue: loc)
        urlElement.addChild(locElement)

        // Add lastmod (optional)
        if let lastmod = lastmod {
            let lastmodElement = XMLElement(name: "lastmod", stringValue: lastmod)
            urlElement.addChild(lastmodElement)
        }

        // Add changefreq
        let changefreqElement = XMLElement(name: "changefreq", stringValue: changefreq)
        urlElement.addChild(changefreqElement)

        // Add priority
        let priorityElement = XMLElement(name: "priority", stringValue: priority)
        urlElement.addChild(priorityElement)

        return urlElement
    }
}
