import Foundation
import System

public enum BlogInitializer {
    public static func copyTemplateFiles(to templatesDirectory: FilePath) throws {
        let fileManager = FileManager.default
        let bundle = Bundle.module

        let templateFiles = [
            "layout.html.mustache",
            "article.html.mustache",
            "list.html.mustache",
        ]

        for templateFile in templateFiles {
            // Remove .mustache extension for resource lookup
            let resourceName = String(templateFile.dropLast(9))

            guard let bundlePath = bundle.path(forResource: resourceName, ofType: "mustache") else {
                throw TuzuruError.templateNotFound(templateFile)
            }

            let destinationPath = templatesDirectory.appending(templateFile)
            try fileManager.copyItem(atPath: bundlePath, toPath: destinationPath.string)
        }
    }
}
