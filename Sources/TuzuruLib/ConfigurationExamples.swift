import Foundation

/// Examples of how to create custom site configurations
public extension SiteConfiguration {
    
    /// Example configuration for a personal blog
    static let personalBlog = SiteConfiguration(
        templates: TemplateConfiguration(
            layoutFile: "layouts/main.mustache",
            articleFile: "templates/post.html",
            listFile: "templates/index.html"
        ),
        output: OutputConfiguration(
            directory: "public",
            indexFileName: "index.html",
            pageExtension: ".html"
        ),
        metadata: SiteMetadata(
            blogTitle: "Jane's Tech Blog",
            copyright: "2025 Jane Doe",
            listPageTitle: "Latest Posts"
        )
    )
    
    /// Example configuration for a documentation site
    static let documentation = SiteConfiguration(
        templates: TemplateConfiguration(
            layoutFile: "theme/doc.mustache",
            articleFile: "theme/article.html",
            listFile: "theme/toc.html"
        ),
        output: OutputConfiguration(
            directory: "docs",
            indexFileName: "index.html",
            pageExtension: ".html"
        ),
        metadata: SiteMetadata(
            blogTitle: "API Documentation",
            copyright: "2025 Acme Corp",
            listPageTitle: "Table of Contents"
        )
    )
    
    /// Example configuration for a portfolio site
    static let portfolio = SiteConfiguration(
        templates: TemplateConfiguration(
            layoutFile: "portfolio.mustache",
            articleFile: "project.html",
            listFile: "gallery.html"
        ),
        output: OutputConfiguration(
            directory: "build",
            indexFileName: "portfolio.html",
            pageExtension: ".html"
        ),
        metadata: SiteMetadata(
            blogTitle: "John's Portfolio",
            copyright: "2025 John Smith",
            listPageTitle: "My Work"
        )
    )
    
    /// Example configuration with different output format
    static let xmlSite = SiteConfiguration(
        output: OutputConfiguration(
            directory: "xml-site",
            indexFileName: "sitemap.xml",
            pageExtension: ".xml"
        )
    )
}