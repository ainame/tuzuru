import Foundation
import System
import Testing
@testable import TuzuruLib

@Suite
struct PathGeneratorTests {

    // MARK: - Test Fixtures

    let contentsBasePath = FilePath("/contents")

    func makeDirectOutputConfig() -> OutputOptions {
        OutputOptions(directory: "blog", style: .direct)
    }

    func makeSubdirectoryOutputConfig() -> OutputOptions {
        OutputOptions(directory: "blog", style: .subdirectory)
    }

    // MARK: - generateOutputPath Tests

    @Test("Generate output path for top-level file in direct style")
    func generateOutputPathTopLevelDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/welcome.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "welcome.html")
    }

    @Test("Generate output path for nested file in direct style")
    func generateOutputPathNestedDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "tech/swift-concurrency.html")
    }

    @Test("Generate output path for deeply nested file in direct style")
    func generateOutputPathDeeplyNestedDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/2024/10/01/diary.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "2024/10/01/diary.html")
    }

    @Test("Generate output path for top-level file in subdirectory style")
    func generateOutputPathTopLevelSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/welcome.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "welcome/index.html")
    }

    @Test("Generate output path for nested file in subdirectory style")
    func generateOutputPathNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "tech/swift-concurrency/index.html")
    }

    @Test("Generate output path for deeply nested file in subdirectory style")
    func generateOutputPathDeeplyNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/2024/10/01/diary.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "2024/10/01/diary/index.html")
    }

    // MARK: - generateUrl Tests

    @Test("Generate URL for top-level file in direct style")
    func generateUrlTopLevelDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/welcome.md")

        let result = pathGenerator.generateUrl(for: articlePath)

        #expect(result == "welcome.html")
    }

    @Test("Generate URL for nested file in subdirectory style")
    func generateUrlNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateUrl(for: articlePath)

        #expect(result == "tech/swift-concurrency/")
    }

    // MARK: - generateHomeUrl Tests

    @Test("Generate home URL from top-level article in direct style")
    func generateHomeUrlTopLevelDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/welcome.md")

        let result = pathGenerator.generateHomeUrl(from: articlePath)

        #expect(result == "index.html")
    }

    @Test("Generate home URL from nested article in direct style")
    func generateHomeUrlNestedDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateHomeUrl(from: articlePath)

        #expect(result == "../index.html")
    }

    @Test("Generate home URL from deeply nested article in direct style")
    func generateHomeUrlDeeplyNestedDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/2024/10/01/diary.md")

        let result = pathGenerator.generateHomeUrl(from: articlePath)

        #expect(result == "../../../index.html")
    }

    @Test("Generate home URL from nested article in subdirectory style")
    func generateHomeUrlNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateHomeUrl(from: articlePath)

        #expect(result == "../../")
    }

    @Test("Generate home URL from deeply nested article in subdirectory style")
    func generateHomeUrlDeeplyNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/2024/10/01/diary.md")

        let result = pathGenerator.generateHomeUrl(from: articlePath)

        #expect(result == "../../../../")
    }

    @Test("Generate home URL for index page")
    func generateHomeUrlForIndexPage() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)

        let result = pathGenerator.generateHomeUrl(from: nil)

        #expect(result == "./")
    }

    // MARK: - generateAssetsUrl Tests

    @Test("Generate assets URL from top-level article in direct style")
    func generateAssetsUrlTopLevelDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/welcome.md")

        let result = pathGenerator.generateAssetsUrl(from: articlePath)

        #expect(result == "assets/")
    }

    @Test("Generate assets URL from nested article in direct style")
    func generateAssetsUrlNestedDirect() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateAssetsUrl(from: articlePath)

        #expect(result == "../assets/")
    }

    @Test("Generate assets URL from nested article in subdirectory style")
    func generateAssetsUrlNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/swift-concurrency.md")

        let result = pathGenerator.generateAssetsUrl(from: articlePath)

        #expect(result == "../../assets/")
    }

    @Test("Generate assets URL from deeply nested article in subdirectory style")
    func generateAssetsUrlDeeplyNestedSubdirectory() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/2024/10/01/diary.md")

        let result = pathGenerator.generateAssetsUrl(from: articlePath)

        #expect(result == "../../../../assets/")
    }

    @Test("Generate assets URL for index page")
    func generateAssetsUrlForIndexPage() async throws {
        let pathGenerator = PathGenerator(configuration: makeSubdirectoryOutputConfig(), contentsBasePath: contentsBasePath)

        let result = pathGenerator.generateAssetsUrl(from: nil)

        #expect(result == "assets/")
    }

    // MARK: - Edge Cases

    @Test("Handle file with missing extension")
    func handleFileWithMissingExtension() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/noextension")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "tech/noextension.html")
    }

    @Test("Handle file with multiple dots in name")
    func handleFileWithMultipleDots() async throws {
        let pathGenerator = PathGenerator(configuration: makeDirectOutputConfig(), contentsBasePath: contentsBasePath)
        let articlePath = FilePath("/contents/tech/my.article.name.md")

        let result = pathGenerator.generateOutputPath(for: articlePath)

        #expect(result == "tech/my.article.name.html")
    }
}
