import Testing
import Foundation
@testable import TuzuruLib

@Suite(.gitRepositoryFixture)
struct GenerateManifestTests {
    
    @Test("Create manifest with source directories and files")
    func testCreateManifest() async throws {
        // Setup
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager
        
        // Create test directories and files
        let contentsDir = fileManager.workingDirectory.appending("contents")
        let assetsDir = fileManager.workingDirectory.appending("assets")
        let unlistedDir = fileManager.workingDirectory.appending("contents/unlisted")
        
        try fileManager.createDirectory(atPath: contentsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: assetsDir, withIntermediateDirectories: true)
        try fileManager.createDirectory(atPath: unlistedDir, withIntermediateDirectories: true)
        
        let generatedFiles = [
            FilePath("blog/index.html"),
            FilePath("blog/post1.html"),
            FilePath("blog/2024/index.html")
        ]
        
        // Create manifest
        let manifest = try GenerateManifest(
            sourceDirs: [contentsDir, assetsDir, unlistedDir],
            generatedFiles: generatedFiles,
            fileManager: fileManager
        )
        
        // Verify manifest properties
        #expect(manifest.generatedAt > 0)
        #expect(manifest.sourceDirs.count == 3)
        #expect(manifest.sourceDirs.keys.contains { FilePath($0) == contentsDir })
        #expect(manifest.sourceDirs.keys.contains { FilePath($0) == assetsDir })
        #expect(manifest.sourceDirs.keys.contains { FilePath($0) == unlistedDir })
        #expect(manifest.files.count == 3)
        #expect(manifest.files.contains { FilePath($0) == FilePath("blog/index.html") })
        #expect(manifest.files.contains { FilePath($0) == FilePath("blog/post1.html") })
        #expect(manifest.files.contains { FilePath($0) == FilePath("blog/2024/index.html") })
    }
    
    @Test("Save and load manifest")
    func testSaveAndLoadManifest() async throws {
        // Setup
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager
        
        let contentsDir = fileManager.workingDirectory.appending("contents")
        try fileManager.createDirectory(atPath: contentsDir, withIntermediateDirectories: true)
        
        let generatedFiles = [FilePath("blog/index.html")]
        let manifest = try GenerateManifest(
            sourceDirs: [contentsDir],
            generatedFiles: generatedFiles,
            fileManager: fileManager
        )
        
        let manifestPath = fileManager.workingDirectory.appending(".build/manifest.json")
        
        // Save manifest
        try manifest.save(to: manifestPath, fileManager: fileManager)
        
        // Verify file was created
        #expect(fileManager.fileExists(atPath: manifestPath))
        
        // Load manifest
        let loadedManifest = try GenerateManifest.load(from: manifestPath, fileManager: fileManager)
        
        // Verify loaded manifest matches original
        #expect(loadedManifest != nil)
        #expect(loadedManifest!.generatedAt == manifest.generatedAt)
        #expect(loadedManifest!.sourceDirs == manifest.sourceDirs)
        #expect(loadedManifest!.files == manifest.files)
    }
    
    @Test("Get orphaned files correctly")
    func testGetOrphanedFiles() async throws {
        // Setup
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager
        
        let contentsDir = fileManager.workingDirectory.appending("contents")
        try fileManager.createDirectory(atPath: contentsDir, withIntermediateDirectories: true)
        
        let originalFiles = [
            FilePath("blog/index.html"),
            FilePath("blog/post1.html"),
            FilePath("blog/post2.html")
        ]
        
        let manifest = try GenerateManifest(
            sourceDirs: [contentsDir],
            generatedFiles: originalFiles,
            fileManager: fileManager
        )
        
        // Current files (post2.html was removed)
        let currentFiles = [
            FilePath("blog/index.html").string,
            FilePath("blog/post1.html").string
        ]
        
        let orphanedFiles = manifest.getOrphanedFiles(currentFiles: currentFiles)
        
        #expect(orphanedFiles.count == 1)
        #expect(orphanedFiles.contains { FilePath($0) == FilePath("blog/post2.html") })
    }
    
    @Test("Load non-existent manifest returns nil")
    func testLoadNonExistentManifest() async throws {
        let fixture = Environment.gitRepositoryFixture!
        let fileManager = fixture.fileManager
        
        let nonExistentPath = fileManager.workingDirectory.appending(".build/nonexistent.json")
        
        let manifest = try GenerateManifest.load(from: nonExistentPath, fileManager: fileManager)
        #expect(manifest == nil)
    }
}