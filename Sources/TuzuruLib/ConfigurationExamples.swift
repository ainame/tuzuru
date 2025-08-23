import Foundation

/// Examples of how to create custom Blog configurations
public extension BlogConfiguration {

    /// Example configuration for a personal blog
    static let personalBlog = BlogConfiguration(
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
        metadata: BlogMetadata(
            blogTitle: "Jane's Tech Blog",
            copyright: "2025 Jane Doe",
            listPageTitle: "Latest Posts"
        )
    )
    
    /// Example configuration for a documentation Blog
    static let documentation = BlogConfiguration(
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
        metadata: BlogMetadata(
            blogTitle: "API Documentation",
            copyright: "2025 Acme Corp",
            listPageTitle: "Table of Contents"
        )
    )
    
    /// Example configuration for a portfolio Blog
    static let portfolio = BlogConfiguration(
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
        metadata: BlogMetadata(
            blogTitle: "John's Portfolio",
            copyright: "2025 John Smith",
            listPageTitle: "My Work"
        )
    )
    
    /// Example configuration with different output format
    static let xmlSite = BlogConfiguration(
        output: OutputConfiguration(
            directory: "xml-site",
            indexFileName: "sitemap.xml",
            pageExtension: ".xml"
        )
    )
}
