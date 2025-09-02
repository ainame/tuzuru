import ArgumentParser
import Foundation
import TuzuruLib

struct InitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
    )

    mutating func run() async throws {
        let fileManager = FileManagerWrapper(workingDirectory: FileManager.default.currentDirectoryPath)

        print("🚀 Initializing new Tuzuru site...")

        do {
            try await Tuzuru.initializeBlog(fileManager: fileManager)
            
            print("⚙️ Generated tuzuru.json")
            print("  ✅ Created tuzuru.json")
            
            print("📄 Copied template files...")
            print("  ✅ Copied template files")
            
            print("🎨 Copied asset files...")
            print("  ✅ Copied main.css to assets/")
            
            print("📁 Created directory structure...")
            print("  ✅ Created contents/")
            print("  ✅ Created unlisted/")
            
            print("🎉 Site initialized successfully!")
            print("📋 Next steps:")
            print("  1. Add your markdown files to contents/")
            print("  2. Add unlisted pages (like /about) to contents/unlisted/")
            print("  3. Customize templates in templates/")
            print("  4. Run 'tuzuru generate' to build your site")
            
        } catch let error as TuzuruError {
            print("❌ \(error.localizedDescription)")
            return
        } catch {
            print("⚠️ Warning: Initialization completed with some issues: \(error)")
        }
    }
}
