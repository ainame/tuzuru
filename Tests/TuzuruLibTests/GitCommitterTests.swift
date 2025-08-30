import Testing
@testable import TuzuruLib
import Foundation

@Suite
struct GitCommitterTests {
    let gitCommitter = GitCommitter()
    
    @Test("Generate import commit message")
    func generateImportCommitMessage() {
        let title = "My Amazing Post"
        let originalDate = Date(timeIntervalSince1970: 1609718695) // 2021-01-04T03:24:55Z
        
        let message = gitCommitter.generateImportCommitMessage(title: title, originalDate: originalDate)
        
        #expect(message.contains("[tuzuru import]: My Amazing Post"))
        #expect(message.contains("originally published"))
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
    
    @Test("Date formatter works correctly")
    func dateFormatterFormatsCorrectly() {
        let date = Date(timeIntervalSince1970: 1609718695) // 2021-01-04T03:24:55Z
        let dateString = ISO8601DateFormatter().string(from: date)
        #expect(!dateString.isEmpty)
        #expect(dateString.contains("2021"))
    }
}
