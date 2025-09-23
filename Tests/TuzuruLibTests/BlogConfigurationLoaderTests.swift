import Foundation
import Testing
@testable import TuzuruLib

@Suite
struct BlogConfigurationLoaderTests {
    @Test
    func testLoadFullTuzuruJson() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let fileManager = FileManagerWrapper(workingDirectory: tempDir.path)
        let loader = BlogConfigurationLoader(fileManager: fileManager)
        try fileManager.createDirectory(atPath: FilePath(tempDir.path), withIntermediateDirectories: true)
        
        let fullConfig = """
        {
          "metadata" : {
            "blogName" : "My Tech Blog",
            "copyright" : "My Tech Blog",
            "description" : "A blog about technology and programming",
            "baseUrl" : "https://mytechblog.com",
            "locale" : "en_GB"
          },
          "output" : {
            "directory" : "public",
            "routingStyle" : "subdirectory"
          },
          "sourceLayout" : {
            "assets" : "assets",
            "contents" : "contents",
            "imported" : "contents/imported",
            "templates" : {
              "layout" : "templates/layout.mustache",
              "list" : "templates/list.mustache",
              "post" : "templates/post.mustache"
            },
            "unlisted" : "contents/unlisted"
          }
        }
        """

        let configPath = tempDir.appendingPathComponent("tuzuru.json").path
        try fullConfig.write(toFile: configPath, atomically: true, encoding: .utf8)

        defer {
            try? fileManager.removeItem(atPath: FilePath(tempDir.path))
        }

        let config = try loader.load(from: "tuzuru.json")

        #expect(config.metadata.blogName == "My Tech Blog")
        #expect(config.metadata.copyright == "My Tech Blog")
        #expect(config.metadata.description == "A blog about technology and programming")
        #expect(config.metadata.baseUrl == "https://mytechblog.com")
        #expect(config.metadata.locale.identifier == "en_GB")
        #expect(config.output.directory == "public")
        #expect(config.output.routingStyle == .subdirectory)
        #expect(config.sourceLayout.assets == FilePath("assets"))
        #expect(config.sourceLayout.contents == FilePath("contents"))
        #expect(config.sourceLayout.imported == FilePath("contents/imported"))
        #expect(config.sourceLayout.unlisted == FilePath("contents/unlisted"))
        #expect(config.sourceLayout.templates.layout == FilePath("templates/layout.mustache"))
        #expect(config.sourceLayout.templates.list == FilePath("templates/list.mustache"))
        #expect(config.sourceLayout.templates.post == FilePath("templates/post.mustache"))
    }

    @Test
    func testLoadMinimumTuzuruJsonWithDefaults() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let fileManager = FileManagerWrapper(workingDirectory: tempDir.path)
        let loader = BlogConfigurationLoader(fileManager: fileManager)
        try fileManager.createDirectory(atPath: FilePath(tempDir.path), withIntermediateDirectories: true)

        let minimumConfig = """
        {
          "metadata" : {
            "blogName" : "Simple Blog",
            "copyright" : "Simple Blog",
            "description" : "A simple blog",
            "baseUrl" : "",
            "locale" : "en_US"
          },
        }
        """

        let configPath = tempDir.appendingPathComponent("tuzuru.json").path
        try minimumConfig.write(toFile: configPath, atomically: true, encoding: .utf8)

        defer {
            try? fileManager.removeItem(atPath: FilePath(tempDir.path))
        }

        let config = try loader.load(from: "tuzuru.json")

        // Verify explicitly provided metadata
        #expect(config.metadata.blogName == "Simple Blog")
        #expect(config.metadata.copyright == "Simple Blog")
        #expect(config.metadata.description == "A simple blog")
        #expect(config.metadata.baseUrl == "")
        #expect(config.metadata.locale.identifier == "en_US")

        // Verify default values are used for missing fields
        #expect(config.output.directory == "blog")
        #expect(config.output.routingStyle == .subdirectory)
        #expect(config.sourceLayout.assets == FilePath("assets"))
        #expect(config.sourceLayout.contents == FilePath("contents"))
        #expect(config.sourceLayout.imported == FilePath("contents/imported"))
        #expect(config.sourceLayout.unlisted == FilePath("contents/unlisted"))
        #expect(config.sourceLayout.templates.layout == FilePath("templates/layout.mustache"))
        #expect(config.sourceLayout.templates.list == FilePath("templates/list.mustache"))
        #expect(config.sourceLayout.templates.post == FilePath("templates/post.mustache"))
    }
}
