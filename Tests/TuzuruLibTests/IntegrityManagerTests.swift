import Testing
import Foundation
@testable import TuzuruLib

@Suite(.gitRepositoryFixture)
struct IntegrityManagerTests {

    @Test("Initialize integrity manager with correct manifest path")
    func testManifestPath() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager

        let configuration = BlogConfiguration.default
        let integrityManager = IntegrityManager(fileManager: fileManager, blogConfiguration: configuration)

        let expectedPath = fileManager.workingDirectory.appending(".build/manifest.json")
        #expect(integrityManager.manifestPath == expectedPath)
    }

    @Test("Track source directories correctly")
    func testSourceDirectoriesToTrack() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager

        let configuration = BlogConfiguration.default
        let integrityManager = IntegrityManager(fileManager: fileManager, blogConfiguration: configuration)

        // The default configuration expects these relative paths
        let expectedContentsDir = fileManager.workingDirectory.appending("contents")
        let expectedUnlistedDir = fileManager.workingDirectory.appending("contents/unlisted")
        let expectedAssetsDir = fileManager.workingDirectory.appending("assets")

        // Create the directories that the configuration expects
        try fileManager.createDirectory(atPath: expectedContentsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: expectedUnlistedDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: expectedAssetsDir, withIntermediateDirectories: true)

        let trackedDirs = integrityManager.sourceDirectoriesToTrack

        #expect(trackedDirs.count == 3)
        #expect(trackedDirs.contains(expectedContentsDir))
        #expect(trackedDirs.contains(expectedUnlistedDir))
        #expect(trackedDirs.contains(expectedAssetsDir))
    }

    @Test("Return nil when no manifest exists")
    func testLoadNonExistentManifest() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager

        let configuration = BlogConfiguration.default
        let integrityManager = IntegrityManager(fileManager: fileManager, blogConfiguration: configuration)

        let manifest = try integrityManager.loadExistingManifest()
        #expect(manifest == nil)
    }

    @Test("Save and load new manifest")
    func testSaveAndLoadNewManifest() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager

        let configuration = BlogConfiguration.default
        let integrityManager = IntegrityManager(fileManager: fileManager, blogConfiguration: configuration)

        // Create source directories
        let contentsDir = fileManager.workingDirectory.appending("contents")
        let assetsDir = fileManager.workingDirectory.appending("assets")

        try fileManager.createDirectory(atPath: contentsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)

        let generatedFiles = [
            FilePath("blog/index.html"),
            FilePath("blog/post1.html"),
            FilePath("blog/sitemap.xml"),
        ]

        // Save new manifest
        try integrityManager.saveNewManifest(generatedFiles: generatedFiles)

        // Verify manifest was created
        #expect(fileManager.fileExists(atPath: integrityManager.manifestPath))

        // Load and verify content
        let savedManifest = try integrityManager.loadExistingManifest()
        #expect(savedManifest != nil)
        #expect(savedManifest!.files.count == 3)
        #expect(savedManifest!.files.contains { FilePath($0) == FilePath("blog/index.html") })
        #expect(savedManifest!.files.contains { FilePath($0) == FilePath("blog/post1.html") })
        #expect(savedManifest!.files.contains { FilePath($0) == FilePath("blog/sitemap.xml") })
    }
}
