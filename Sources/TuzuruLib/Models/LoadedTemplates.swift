import Mustache

public struct LoadedTemplates: Sendable {
    public let layout: MustacheTemplate
    public let post: MustacheTemplate
    public let list: MustacheTemplate
}
