import Foundation
import Testing

@testable import TuzuruLib

@Suite(.gitRepositoryFixture)
struct GitLogReaderTests {

    @Test
    func testBaseCommitWithoutMarkerCommits() async throws {
        let fixture = Environment.gitRepositoryFixture!
        // Create a test markdown file
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Test Post

                This is a test post for git log testing.
                """
        )

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with test post")

        // Add another regular commit
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Test Post

                This is a test post for git log testing.
                Updated content.
                """)
        try await fixture.createCommit(message: "Update test post content")

        // Test GitLogReader
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        let filePath = FilePath("test-post.md")
        let baseCommit = await gitLogReader.baseCommit(for: filePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage == "Initial commit with test post")
        #expect(baseCommit?.author == "Test User")
        #expect(baseCommit?.email == "test@example.com")
    }

    @Test
    func testBaseCommitWithMarkerCommits() async throws {
        let fixture = Environment.gitRepositoryFixture!
        // Create a test markdown file
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Test Post

                This is a test post for git log testing.
                """)

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with test post")

        // Add regular update
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Updated Test Post

                This is a test post for git log testing.
                Updated content.
                """
        )
        try await fixture.createCommit(message: "Update test post content")

        // Create marker commit for amend operation
        try await fixture.createMarkerCommit(for: "test-post.md", field: "publishedAt")

        // Add another regular commit
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Updated Test Post Again

                This is a test post for git log testing.
                Updated content again.
                """)
        try await fixture.createCommit(message: "Another update to test post")

        // Test GitLogReader - should find the marker commit, not the original
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        let filePath = FilePath("test-post.md")
        let baseCommit = await gitLogReader.baseCommit(for: filePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt") == true)
        #expect(baseCommit?.commitMessage.contains("test-post.md") == true)
    }

    @Test
    func testBaseCommitWithMultipleMarkerCommits() async throws {
        let fixture = Environment.gitRepositoryFixture!
        // Create a test markdown file
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Test Post

                This is a test post for git log testing.
                """)

        // Create initial commit
        try await fixture.createCommit(message: "Initial commit with test post")

        // Create first marker commit (older)
        try await fixture.createMarkerCommit(for: "test-post.md", field: "author")

        // Add regular commit
        try fixture.writeFile(
            at: "test-post.md",
            content: """
                # Updated Test Post

                This is a test post for git log testing.
                """)
        try await fixture.createCommit(message: "Update content")

        // Create second marker commit (newer)
        try await fixture.createMarkerCommit(for: "test-post.md", field: "publishedAt")

        // Test GitLogReader - should find the most recent marker commit
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        let filePath = FilePath("test-post.md")
        let baseCommit = await gitLogReader.baseCommit(for: filePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt") == true)
        #expect(baseCommit?.commitMessage.contains("test-post.md") == true)
    }

    @Test
    func testBaseCommitWithNonExistentFile() async throws {
        let fixture = Environment.gitRepositoryFixture!
        // Create initial commit with different file
        try fixture.writeFile(at: "other-file.md", content: "# Other File")
        try await fixture.createCommit(message: "Initial commit")

        // Test GitLogReader with non-existent file
        let gitLogReader = GitLogReader(
            workingDirectory: fixture.fileManager.workingDirectory
        )
        let filePath = FilePath("non-existent.md")
        let baseCommit = await gitLogReader.baseCommit(for: filePath)

        #expect(baseCommit == nil)
    }
}
