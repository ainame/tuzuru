import Foundation
import System

/// Configuration for site generation, eliminating hardcoded assumptions
public struct SiteConfiguration {
    /// Template file paths
    public let templates: TemplateConfiguration
    
    /// Output configuration
    public let output: OutputConfiguration
    
    /// Site metadata
    public let metadata: SiteMetadata
    
    public init(
        templates: TemplateConfiguration = TemplateConfiguration(),
        output: OutputConfiguration = OutputConfiguration(),
        metadata: SiteMetadata = SiteMetadata()
    ) {
        self.templates = templates
        self.output = output
        self.metadata = metadata
    }
}

/// Template file configuration
public struct TemplateConfiguration {
    /// Layout template file path (e.g., "layout.mustache")
    public let layoutFile: String
    
    /// Article template file path (e.g., "article.html")
    public let articleFile: String
    
    /// List template file path (e.g., "list.html")
    public let listFile: String
    
    public init(
        layoutFile: String = "layout.mustache",
        articleFile: String = "article.html",
        listFile: String = "list.html"
    ) {
        self.layoutFile = layoutFile
        self.articleFile = articleFile
        self.listFile = listFile
    }
}

/// Output file and directory configuration
public struct OutputConfiguration {
    /// Output directory name (e.g., "site", "build", "dist")
    public let directory: String
    
    /// Index page filename (e.g., "index.html")
    public let indexFileName: String
    
    /// File extension for generated pages (e.g., ".html")
    public let pageExtension: String
    
    public init(
        directory: String = "site",
        indexFileName: String = "index.html",
        pageExtension: String = ".html"
    ) {
        self.directory = directory
        self.indexFileName = indexFileName
        self.pageExtension = pageExtension
    }
    
    /// Generate filename for a page based on its path
    public func generateFileName(for pagePath: FilePath) -> String {
        let stem = pagePath.lastComponent?.stem ?? "untitled"
        return "\(stem)\(pageExtension)"
    }
}

/// Site metadata configuration
public struct SiteMetadata {
    /// Blog title displayed in layouts
    public let blogTitle: String
    
    /// Copyright notice
    public let copyright: String
    
    /// Default page title for list pages
    public let listPageTitle: String
    
    public init(
        blogTitle: String = "My Blog",
        copyright: String = "2025 My Blog",
        listPageTitle: String = "Blog"
    ) {
        self.blogTitle = blogTitle
        self.copyright = copyright
        self.listPageTitle = listPageTitle
    }
}