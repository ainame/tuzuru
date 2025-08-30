import Foundation

/// Processes Hugo-style shortcodes during content import
/// Converts Hugo shortcode syntax to standard HTML for Tuzuru compatibility
struct HugoShortcodeProcessor: Sendable {

    /// Process Hugo shortcodes in markdown content during import
    /// This converts shortcodes to HTML that will be preserved in the final output
    /// - Parameter markdown: The markdown content containing Hugo shortcodes
    /// - Returns: Markdown content with shortcodes converted to HTML
    func processShortcodes(in markdown: String) -> String {
        var result = markdown

        // Process X (Twitter) embeds
        result = processXShortcodes(in: result)

        return result
    }

    // MARK: - Private Methods

    /// Process {{< x user="username" id="tweetid" >}} shortcodes
    private func processXShortcodes(in markdown: String) -> String {
        let pattern = #"\{\{<\s*x\s+user="([^"]+)"\s+id="([^"]+)"\s*>\}\}"#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return markdown
        }

        var result = markdown
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: markdown.utf16.count))

        // Process matches in reverse order to maintain string indices
        for match in matches.reversed() {
            let fullRange = Range(match.range, in: markdown)!
            let userRange = Range(match.range(at: 1), in: markdown)!
            let idRange = Range(match.range(at: 2), in: markdown)!

            let user = String(markdown[userRange])
            let id = String(markdown[idRange])

            let embedHTML = generateXEmbedHTML(user: user, id: id)
            result.replaceSubrange(fullRange, with: embedHTML)
        }

        return result
    }

    /// Generate Twitter embed HTML compatible with Twitter's widget system
    private func generateXEmbedHTML(user: String, id: String) -> String {
        return """
        <blockquote class="twitter-tweet" data-dnt="true">
            <p>Loading tweet...</p>
            <a href="https://twitter.com/\(user)/status/\(id)">Tweet by @\(user)</a>
        </blockquote>
        <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
        """
    }
}
