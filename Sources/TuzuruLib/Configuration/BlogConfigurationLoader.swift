import Foundation

public struct BlogConfigurationLoader {
    
    public enum LoadError: Error, LocalizedError {
        case configFileNotFound(String)
        case invalidConfigurationData(Error)
        
        public var errorDescription: String? {
            switch self {
            case .configFileNotFound(let path):
                return "Configuration file not found: \(path). Run 'tuzuru init' first to initialize a new site."
            case .invalidConfigurationData(let error):
                return "Invalid configuration data in tuzuru.json: \(error.localizedDescription)"
            }
        }
    }
    
    public init() {}
    
    /// Loads BlogConfiguration from the specified path, or from default "tuzuru.json" in current directory
    /// - Parameter configPath: Optional path to configuration file. If nil, uses "tuzuru.json" in current directory
    /// - Returns: Loaded BlogConfiguration
    /// - Throws: LoadError if file not found or invalid
    public func load(from configPath: String? = nil) throws -> BlogConfiguration {
        let finalPath: String
        
        if let configPath = configPath {
            finalPath = configPath
        } else {
            let currentPath = FilePath(FileManager.default.currentDirectoryPath)
            finalPath = currentPath.appending("tuzuru.json").string
        }
        
        guard FileManager.default.fileExists(atPath: finalPath) else {
            throw LoadError.configFileNotFound(finalPath)
        }
        
        do {
            let configData = try Data(contentsOf: URL(fileURLWithPath: finalPath))
            let decoder = JSONDecoder()
            return try decoder.decode(BlogConfiguration.self, from: configData)
        } catch {
            throw LoadError.invalidConfigurationData(error)
        }
    }
}
