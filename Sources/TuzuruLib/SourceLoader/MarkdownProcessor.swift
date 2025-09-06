import Foundation
import Markdown

/// Handles processing raw markdown content to HTML with various transformations
struct MarkdownProcessor {
    func process(_ rawPost: RawPost) throws -> Post {
        // Parse markdown document
        let document = Document(parsing: rawPost.content)
        var destructor = MarkdownDestructor()
        var xPostConverter = XPostLinkConverter()
        var urlLinker = URLLinker()
        var escaper = CodeBlockHTMLEscaper()
        var htmlFormatter = CustomHTMLFormatter()
        var excerptWalker = MarkdownExcerptWalker(maxLength: 150)

        // First, try to extract title and process with destructor
        let processedDocument = destructor.visit(document)

        guard let finalTitle = destructor.title else {
            throw TuzuruError.titleNotFound("No H1 title found in markdown file: \(rawPost.path.string)")
        }

        let documentToProcess = processedDocument!

        // Process the document through the remaining pipeline
        xPostConverter.visit(documentToProcess)
            .flatMap { urlLinker.visit($0) }
            .flatMap { escaper.visit($0) }
            .flatMap {
                // Format HTML with custom processor and walk for excerpt
                htmlFormatter.visit($0)
                excerptWalker.visit($0)
            }

        // Return processed post with HTML content and extracted metadata
        return Post(
            path: rawPost.path,
            title: finalTitle,
            author: rawPost.author,
            publishedAt: rawPost.publishedAt,
            excerpt: excerptWalker.result,
            content: rawPost.content,  // Preserve raw markdown content
            htmlContent: htmlFormatter.result,
            isUnlisted: rawPost.isUnlisted
        )
    }
}
