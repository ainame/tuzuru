import Testing
@testable import TuzuruLib
import Foundation

@Suite(.gitRepositoryFixture)
struct GitCommitterTests {
    
    @Test("Generate import commit message")
    func generateImportCommitMessage() {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        let title = "My Amazing Post"
        let originalDate = Date(timeIntervalSince1970: 1609718695) // 2021-01-04T03:24:55Z
        
        let message = gitCommitter.generateImportCommitMessage(title: title, originalDate: originalDate)
        
        #expect(message.contains("[tuzuru import]: My Amazing Post"))
        #expect(message.contains("originally published"))
        #expect(message.contains("2021-01-04"))
    }
    
    @Test("Error descriptions are meaningful")
    func gitCommitterErrorDescriptions() {
        let errors: [GitCommitterError] = [
            .commandFailed("git add", "file not found"),
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
    
    @Test("Commit single file successfully")
    func commitSingleFileSuccessfully() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        // Create a test file to commit
        let testContent = """
        ---
        title: "Test Post"
        date: 2023-01-15
        ---
        
        # Test Post
        
        This is test content.
        """
        
        try fixture.writeFile(at: "test-post.md", content: testContent)
        
        let message = "Add test post"
        let date = Date(timeIntervalSince1970: 1673827200) // 2023-01-15T20:00:00Z
        
        // Commit the file
        try await gitCommitter.commit(
            filePath: "test-post.md",
            message: message,
            date: date,
            author: "Test Author <test@example.com>"
        )
        
        // Verify the commit was created by checking git log
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        let baseCommit = await gitLogReader.baseCommit(for: FilePath("test-post.md"))
        
        #expect(baseCommit != nil)
        #expect(baseCommit!.commitMessage == message)
        #expect(baseCommit!.author == "Test Author")
    }
    
    @Test("Commit batch of files successfully")
    func commitBatchOfFilesSuccessfully() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        // Create multiple test files
        let files = [
            ("post1.md", "# Post 1\nContent 1"),
            ("post2.md", "# Post 2\nContent 2"),
            ("post3.md", "# Post 3\nContent 3")
        ]
        
        for (filename, content) in files {
            try fixture.writeFile(at: filename, content: content)
        }
        
        let message = "Batch import posts"
        let date = Date(timeIntervalSince1970: 1673827200)
        let author = "Batch Author <batch@example.com>"
        let filePaths = files.map { $0.0 }
        
        // Commit all files in batch
        try await gitCommitter.commitBatch(filePaths.map { filePath in
            (
                filePath: FilePath(filePath),
                message: message,
                date: date,
                author: author
            )
        })
        
        // Verify all files are committed
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        
        for filePath in filePaths {
            let baseCommit = await gitLogReader.baseCommit(for: FilePath(filePath))
            #expect(baseCommit != nil)
            #expect(baseCommit!.commitMessage == message)
            #expect(baseCommit!.author == "Batch Author")
        }
    }
    
    @Test("Commit without author parameter uses current git config")
    func commitWithoutAuthorUsesGitConfig() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        // Create a test file to commit
        try fixture.writeFile(at: "no-author-post.md", content: "# No Author Test")
        
        let message = "Test commit without explicit author"
        let date = Date(timeIntervalSince1970: 1673827200)
        
        // Commit without specifying author (should use git config)
        try await gitCommitter.commit(
            filePath: "no-author-post.md",
            message: message,
            date: date,
            author: nil
        )
        
        // Verify the commit was created
        let gitLogReader = GitLogReader(workingDirectory: fixture.path)
        let baseCommit = await gitLogReader.baseCommit(for: FilePath("no-author-post.md"))
        
        #expect(baseCommit != nil)
        #expect(baseCommit!.commitMessage == message)
        // Author should be from git config (Test User from GitRepositoryFixture)
        #expect(baseCommit!.author == "Test User")
    }
    
    @Test("Date formatter works correctly")
    func dateFormatterFormatsCorrectly() {
        let date = Date(timeIntervalSince1970: 1609718695) // 2021-01-04T03:24:55Z
        let dateString = ISO8601DateFormatter().string(from: date)
        #expect(!dateString.isEmpty)
        #expect(dateString.contains("2021"))
    }
    
    @Test("Generate commit message with special characters in title")
    func generateCommitMessageWithSpecialCharacters() {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        let title = "Post with \"quotes\" & special <characters>"
        let originalDate = Date(timeIntervalSince1970: 1609718695)
        
        let message = gitCommitter.generateImportCommitMessage(title: title, originalDate: originalDate)
        
        #expect(message.contains("[tuzuru import]: Post with \"quotes\" & special <characters>"))
        #expect(message.contains("originally published"))
    }
    
    @Test("Generate commit message with very long title")
    func generateCommitMessageWithVeryLongTitle() {
        let fixture = Environment.gitRepositoryFixture!
        let gitCommitter = GitCommitter(workingDirectory: fixture.path)
        
        let longTitle = String(repeating: "Very Long Title ", count: 10) + "End"
        let originalDate = Date(timeIntervalSince1970: 1609718695)
        
        let message = gitCommitter.generateImportCommitMessage(title: longTitle, originalDate: originalDate)
        
        #expect(message.contains("[tuzuru import]: \(longTitle)"))
        #expect(message.contains("originally published"))
        #expect(message.contains("2021-01-04"))
    }
}