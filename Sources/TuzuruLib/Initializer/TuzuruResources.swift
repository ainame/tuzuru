import Foundation

enum TuzuruResources {
    private static let environmentVariableName = "TUZURU_RESOURCES"

    static func resourceBundle(fileManager: FileManagerWrapper) throws -> Bundle {
        // Check environment variable first (for Homebrew distribution)
        if ProcessInfo.processInfo.environment[environmentVariableName] != nil {
            return try bundleFromEnvironment(fileManager: fileManager)
        }
        
        // Fall back to Bundle.module for development/normal SPM usage
        return Bundle.module
    }

    private static func bundleFromEnvironment(fileManager: FileManagerWrapper) throws -> Bundle {
        guard let resourcesPathString = ProcessInfo.processInfo.environment[environmentVariableName] else {
            throw TuzuruError.templateNotFound("Resources bundle not found. \(environmentVariableName) environment variable not set.")
        }

        let resourcesPath = FilePath(resourcesPathString)

        // Look for .bundle files in the resources directory
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: resourcesPath)
            let bundleCandidates = contents.filter { $0.extension == "bundle" }

            guard let firstBundle = bundleCandidates.first else {
                throw TuzuruError.templateNotFound("No .bundle file found in resources directory: \(resourcesPathString)")
            }

            guard let bundleComponent = firstBundle.lastComponent else {
                throw TuzuruError.templateNotFound("Invalid bundle path: \(firstBundle)")
            }

            let bundlePath = resourcesPath.appending(bundleComponent)
            let bundleURL = URL(fileURLWithPath: bundlePath.string)

            guard let bundle = Bundle(url: bundleURL) else {
                throw TuzuruError.templateNotFound("Could not load bundle from: \(bundleURL.path)")
            }

            return bundle
        } catch {
            throw TuzuruError.templateNotFound("Could not access resources directory: \(resourcesPathString). Error: \(error)")
        }
    }
}
