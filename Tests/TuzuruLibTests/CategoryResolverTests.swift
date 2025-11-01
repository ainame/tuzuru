import Foundation
import Testing
@testable import TuzuruLib

@Suite
struct CategoryResolverTests {

    // MARK: - Test Fixtures

    let contentsBasePath = FilePath("/blog/contents")

    func makeCategoryResolver(importedDirName: String = "imported") -> CategoryResolver {
        CategoryResolver(
            contentsBasePath: contentsBasePath,
            importedDirName: importedDirName
        )
    }

    // MARK: - extractCategory Tests

    @Test("Extract category from nested post")
    func extractCategoryFromNestedPost() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/tech/swift-tips.md")

        let category = resolver.extractCategory(from: postPath)

        #expect(category == "tech")
    }

    @Test("Extract category from deeply nested post")
    func extractCategoryFromDeeplyNestedPost() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/tutorials/swift/post.md")

        let category = resolver.extractCategory(from: postPath)

        #expect(category == "tutorials")
    }

    @Test("Return nil for post in contents root")
    func returnNilForPostInContentsRoot() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/post.md")

        let category = resolver.extractCategory(from: postPath)

        #expect(category == nil)
    }

    @Test("Exclude imported directory from categories")
    func excludeImportedDirectory() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/imported/old-post.md")

        let category = resolver.extractCategory(from: postPath)

        #expect(category == nil)
    }

    @Test("Use custom imported directory name")
    func useCustomImportedDirectoryName() {
        let resolver = makeCategoryResolver(importedDirName: "archived")
        let archivedPath = FilePath("/blog/contents/archived/post.md")
        let normalPath = FilePath("/blog/contents/tech/post.md")

        let archivedCategory = resolver.extractCategory(from: archivedPath)
        let normalCategory = resolver.extractCategory(from: normalPath)

        #expect(archivedCategory == nil)
        #expect(normalCategory == "tech")
    }

    // MARK: - extractTopLevelDirectory Tests

    @Test("Extract top-level directory without filtering")
    func extractTopLevelDirectory() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/tech/post.md")

        let topLevel = resolver.extractTopLevelDirectory(from: postPath)

        #expect(topLevel == "tech")
    }

    @Test("Extract top-level directory includes imported")
    func extractTopLevelDirectoryIncludesImported() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/imported/post.md")

        let topLevel = resolver.extractTopLevelDirectory(from: postPath)

        #expect(topLevel == "imported")
    }

    @Test("Return nil for top-level when post is in root")
    func returnNilForTopLevelWhenInRoot() {
        let resolver = makeCategoryResolver()
        let postPath = FilePath("/blog/contents/post.md")

        let topLevel = resolver.extractTopLevelDirectory(from: postPath)

        #expect(topLevel == nil)
    }
}
