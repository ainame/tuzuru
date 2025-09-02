import Foundation
import Testing

@testable import TuzuruLib

@Suite(.gitRepositoryFixture)
struct FileAmenderTests {
    @Test
    func testAmendFileWithNewDate() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit with demo content
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        // Set up configuration for the test repo
        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        // Test amending with new date
        let testFilePath = FilePath("contents/technology/swift-basics-for-beginners.md")
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newDate: "2024-01-15",
        )

        // Verify marker commit was created
        let gitLogReader = GitLogReader(
            workingDirectory: gitRepository.path,
        )
        let baseCommit = await gitLogReader.baseCommit(for: testFilePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt") == true)
        #expect(baseCommit?.commitMessage.contains("swift-basics-for-beginners.md") == true)
    }

    @Test
    func testAmendFileWithNewAuthor() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        // Test amending with new author
        let testFilePath = FilePath("contents/technology/introduction-to-machine-learning.md")
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newAuthor: "Jane Doe"
        )

        // Verify marker commit was created with custom author
        let gitLogReader = GitLogReader(
            workingDirectory: gitRepository.path,
        )
        let baseCommit = await gitLogReader.baseCommit(for: testFilePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("author") == true)
        #expect(baseCommit?.author == "Jane Doe")
    }

    @Test
    func testAmendFileWithBothDateAndAuthor() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        // Test amending with both new date and author
        let testFilePath = FilePath("contents/lifestyle/mindful-morning-routine.md")
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newDate: "2024-02-20",
            newAuthor: "John Smith"
        )

        // Verify marker commit was created with both changes
        let gitLogReader = GitLogReader(
            workingDirectory: gitRepository.path,
        )
        let baseCommit = await gitLogReader.baseCommit(for: testFilePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt and author") == true)
        #expect(baseCommit?.commitMessage.contains("mindful-morning-routine.md") == true)
        #expect(baseCommit?.author == "John Smith")
    }

    @Test
    func testAmendFileWithInvalidDate() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        // Test amending with invalid date format
        let testFilePath = FilePath("contents/technology/swift-basics-for-beginners.md")

        await #expect(throws: TuzuruError.self) {
            try await fileAmender.amendFile(
                filePath: testFilePath,
                newDate: "invalid-date-format"
            )
        }
    }

    @Test
    func testAmendNonExistentFile() async throws {
        let gitRepository = Environment.gitRepositoryFixture!

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        // Test amending non-existent file
        let nonExistentPath = FilePath("non-existent.md")

        await #expect(throws: TuzuruError.self) {
            try await fileAmender.amendFile(
                filePath: nonExistentPath,
                newDate: "2024-01-01"
            )
        }
    }

    @Test
    func testMultipleAmendOperations() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        let testFilePath = FilePath("contents/technology/swift-basics-for-beginners.md")

        // First amend - change date
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newDate: "2024-01-15"
        )

        // Second amend - change author
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newAuthor: "Updated Author"
        )

        // Verify the most recent marker commit is found
        let gitLogReader = GitLogReader(workingDirectory: gitRepository.path)
        let baseCommit = await gitLogReader.baseCommit(for: testFilePath)

        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("author") == true)
        #expect(baseCommit?.author == "Updated Author")
    }

    @Test
    func testAmendOnlyDateInheritsAuthorFromPreviousMarkerCommit() async throws {
        let gitRepository = Environment.gitRepositoryFixture!
        try gitRepository.copyFixtures(from: Environment.fixturePath)

        // Create initial commit (uses git config: "Test User")
        try await gitRepository.createCommit(message: "Initial commit with demo content")

        let config = BlogConfiguration.default
        let fileAmender = FileAmender(
            configuration: config,
            fileManager: gitRepository.fileManager
        )

        let testFilePath = FilePath("contents/technology/swift-basics-for-beginners.md")

        // First amend - change both author and date (author=Satoshi2, date=2025-10-02)
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newDate: "2025-10-02",
            newAuthor: "Satoshi2"
        )

        // Verify first marker commit was created correctly
        let gitLogReader = GitLogReader(workingDirectory: gitRepository.path)
        var baseCommit = await gitLogReader.baseCommit(for: testFilePath)
        
        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt and author") == true)
        #expect(baseCommit?.author == "Satoshi2")

        // Second amend - change ONLY the date to 2025-10-03
        // This should inherit author=Satoshi2 from the previous marker commit
        // NOT fall back to git config ("Test User")
        try await fileAmender.amendFile(
            filePath: testFilePath,
            newDate: "2025-10-03"
        )

        // Verify second marker commit preserves the author from previous marker commit
        baseCommit = await gitLogReader.baseCommit(for: testFilePath)
        
        #expect(baseCommit != nil)
        #expect(baseCommit?.commitMessage.hasPrefix("[tuzuru amend]") == true)
        #expect(baseCommit?.commitMessage.contains("publishedAt") == true)
        #expect(baseCommit?.commitMessage.contains("author") == false) // Only date was updated
        
        // CRITICAL TEST: Author should be inherited from previous marker commit (Satoshi2)
        // NOT from git config (Test User)
        #expect(baseCommit?.author == "Satoshi2", "Author should be inherited from previous marker commit, not git config")
        
        // Verify date was updated correctly
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let expectedDate = dateFormatter.date(from: "2025-10-03")!
        
        // Allow some tolerance for date comparison (within same day)
        let calendar = Calendar.current
        #expect(calendar.isDate(baseCommit!.date, inSameDayAs: expectedDate))
    }
}
