import Testing
@testable import TuzuruLib

@Suite
struct DateUtilsTests {
    @Test("Parse Hugo and Jekyll date formats", arguments: [
        // Hugo formats
        ("2023-10-15T13:18:50-07:00", true),  // Hugo with timezone offset
        ("2023-10-15T13:18:50-0700", true),   // Hugo with timezone offset (short)
        ("2023-10-15T13:18:50Z", true),       // Hugo UTC
        ("2023-10-15T13:18:50", true),        // Hugo without timezone
        ("2023-10-15", true),                 // Hugo date only
        ("15 Oct 2023", true),                // Hugo alternative format
        // Jekyll formats
        ("2025-06-05 08:31:19 +0700", true),  // Jekyll with timezone
        ("2025-06-05 08:31:19", true),        // Jekyll without timezone
        ("2025-06-05", true),                 // Jekyll date only
        // Invalid formats
        ("invalid date", false),
        ("2021-13-04", false),                // Invalid month
        ("", false),
    ])
    func parseDateFormats(dateString: String, shouldSucceed: Bool) {
        let result = DateUtils.parseDate(dateString)
        #expect((result != nil) == shouldSucceed, "Date parsing for '\(dateString)' should \(shouldSucceed ? "succeed" : "fail")")
    }
}