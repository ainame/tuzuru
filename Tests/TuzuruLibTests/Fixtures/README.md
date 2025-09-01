# Test Fixtures

This directory contains test fixtures for Tuzuru integration tests.

## DemoProject

The `DemoProject` directory contains content from the Tuzuru-Demo repository:
- `contents/`: Sample markdown blog posts organized by category
- `templates/`: Mustache templates for rendering
- `tuzuru.json`: Sample blog configuration

This content is used by tests tagged with `@Tag(.git)` to create realistic test scenarios with actual blog content.

## Usage

Tests can copy this fixture content into temporary git repositories using the `GitTestRepository` utility:

```swift
@Test(.tags(.git))
func myGitTest() async throws {
    let testRepo = try GitTestRepository()
    let fixturesPath = FilePath(#filePath).removingLastComponent().appending("Fixtures/DemoProject")
    try testRepo.copyFixtures(from: fixturesPath)
    
    // Test with realistic blog content
}
```