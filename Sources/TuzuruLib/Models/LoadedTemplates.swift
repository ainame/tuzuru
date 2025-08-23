import Mustache

public struct LoadedTemplates: Sendable {
    public let layout: MustacheTemplate
    public let article: MustacheTemplate
    public let list: MustacheTemplate
}
