import Foundation
import Testing
@testable import TuzuruLib

enum Environment {
    @TaskLocal static var gitRepositoryFixture: GitRepositoryFixture!

    static let fixturePath = FilePath(#filePath)
        .removingLastComponent()
        .removingLastComponent()
        .appending("Fixtures/DemoProject")
}

struct GitRepositoryFixtureTrait: TestTrait, SuiteTrait, TestScoping {
    let isRecursive = true

    init() {}

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // Create a unique git repository for each test invocation
        let repository = try await GitRepositoryFixture(fileManager: FileManager())
        defer { repository.clear() }

        try await Environment.$gitRepositoryFixture.withValue(repository) {
            try await function()
        }
    }
}

// MARK: - Trait Convenience

extension Trait where Self == GitRepositoryFixtureTrait {
    static var gitRepositoryFixture: Self {
        GitRepositoryFixtureTrait()
    }
}
