import Foundation

enum TuzuruResources {
    private static let environmentVariableName = "TUZURU_RESOURCES"

    static func resourceBundle() throws -> Bundle {
        // Check environment variable first (for Homebrew distribution)
        if ProcessInfo.processInfo.environment[environmentVariableName] != nil {
            return try bundleFromEnvironment()
        }
        
        // Fall back to Bundle.module for development/normal SPM usage
        return Bundle.module
    }

    private static func bundleFromEnvironment() throws -> Bundle {
        guard let resourcesPath = ProcessInfo.processInfo.environment[environmentVariableName] else {
            throw TuzuruError.templateNotFound("Resources bundle not found. \(environmentVariableName) environment variable not set.")
        }

        let resourcesURL = URL(fileURLWithPath: resourcesPath)

        // Look for .bundle files in the resources directory
        let fileManager = FileManager.default
        do {
            let contents = try fileManager.contentsOfDirectory(at: resourcesURL, includingPropertiesForKeys: nil)
            let bundleFiles = contents.filter { $0.pathExtension == "bundle" }

            guard let bundleURL = bundleFiles.first else {
                throw TuzuruError.templateNotFound("No .bundle file found in resources directory: \(resourcesPath)")
            }

            guard let bundle = Bundle(url: bundleURL) else {
                throw TuzuruError.templateNotFound("Could not load bundle from: \(bundleURL.path)")
            }

            return bundle
        } catch {
            throw TuzuruError.templateNotFound("Could not access resources directory: \(resourcesPath). Error: \(error)")
        }
    }
}
