import Foundation
import System

public enum BlogInitializer {
    public static func copyTemplateFiles(to templatesDirectory: FilePath) throws {
        let fileManager = FileManager.default
        let bundle = Bundle.module

        let templateNames = [
            "layout",
            "article",
            "list",
        ]

        for templateName in templateNames {
            guard let bundlePath = bundle.path(forResource: templateName, ofType: "mustache") else {
                throw TuzuruError.templateNotFound(templateName)
            }

            let destinationPath = templatesDirectory.appending("\(templateName).mustache")
            try fileManager.copyItem(atPath: bundlePath, toPath: destinationPath.string)
        }
    }
}
