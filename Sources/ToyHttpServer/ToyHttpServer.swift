import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#endif

public struct HttpRequestContext: Sendable {
    public let method: String
    public let path: String
    public let fullPath: String
    public let timestamp: Date

    public init(method: String, path: String, fullPath: String, timestamp: Date = Date()) {
        self.method = method
        self.path = path
        self.fullPath = fullPath
        self.timestamp = timestamp
    }
}

struct HttpRequest: Sendable {
    let method: String
    let path: String
    let fullPath: String
    let httpVersion: String
    let headers: [String: String]
    let shouldClose: Bool
    
    init(method: String, path: String, fullPath: String, httpVersion: String, headers: [String: String]) {
        self.method = method
        self.path = path
        self.fullPath = fullPath
        self.httpVersion = httpVersion
        self.headers = headers
        
        // Only close if explicitly requested via "Connection: close"
        let connectionHeader = headers["connection"]?.lowercased()
        self.shouldClose = connectionHeader == "close"
    }
}

struct HttpResponse: Sendable {
    let statusCode: Int
    let statusText: String
    let contentType: String
    let data: Data
    
    init(statusCode: Int, contentType: String = "text/plain", data: Data = Data()) {
        self.statusCode = statusCode
        self.contentType = contentType
        self.data = data
        
        switch statusCode {
        case 200: self.statusText = "OK"
        case 404: self.statusText = "Not Found"
        case 405: self.statusText = "Method Not Allowed"
        case 400: self.statusText = "Bad Request"
        default: self.statusText = "Unknown"
        }
    }
    
    func generateResponseString() -> String {
        return """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(data.count)\r
        Connection: keep-alive\r
        Keep-Alive: timeout=30, max=100\r

        """
    }
}

public typealias RequestHook = @Sendable (HttpRequestContext) async throws -> Void
public typealias ResponseHook = @Sendable (HttpRequestContext, Int) async -> Void

/// A basic HTTP server with keep-alive support for local development and testing purposes only.
///
/// Features:
/// - HTTP keep-alive connections (default behavior)
/// - 30-second connection timeout
/// - Maximum 100 requests per connection
/// - Basic GET request support for static files
/// - Connection closes only on timeout, error, or explicit "Connection: close" header
///
/// WARNING: This is NOT a production-ready HTTP server and should never be used
/// in production environments. It lacks many essential features including:
/// - Security measures and input validation
/// - Comprehensive error handling and recovery
/// - Full HTTP/1.1 compliance beyond basic GET requests
/// - Support for POST/PUT requests, cookies, authentication
/// - Advanced connection pooling and resource management
/// - Performance optimizations for high load
///
/// This server is intended solely for serving static files during local development
/// of the Tuzuru static blog generator.

public class ToyHttpServer {
    private let port: Int
    private let servePath: String
    private let beforeResponseHook: RequestHook?
    private let afterResponseHook: ResponseHook?

    public init(
        port: Int,
        servePath: String,
        beforeResponseHook: RequestHook? = nil,
        afterResponseHook: ResponseHook? = nil
    ) {
        self.port = port
        self.servePath = servePath
        self.beforeResponseHook = beforeResponseHook
        self.afterResponseHook = afterResponseHook
    }

    public func start() async throws {
        let serverSocket = try Socket.createServerSocket(port: port)

        print("⚠️  This is a basic HTTP server that might have issues. Report me any issues at: https://github.com/ainame/Tuzuru/issues")
        print("")
        print("🚀 Starting server on http://localhost:\(port)")
        print("📂 Serving directory: \(servePath)")
        print("🛑 Press Ctrl+C to stop")

        signal(SIGINT) { _ in exit(0) }

        await withTaskGroup(of: Void.self) { group in
            while true {
                guard let clientSocket = Socket.accept(serverSocket) else { continue }

                group.addTask { @Sendable [
                    servePath = self.servePath,
                    beforeHook = self.beforeResponseHook,
                    afterHook = self.afterResponseHook
                ] in
                    await ToyHttpServer.handleClientInstance(
                        clientSocket,
                        servePath: servePath,
                        beforeHook: beforeHook,
                        afterHook: afterHook
                    )
                }
            }
        }
    }

    private static func handleClientInstance(
        _ clientSocket: Socket,
        servePath: String,
        beforeHook: RequestHook?,
        afterHook: ResponseHook?
    ) async {
        defer { clientSocket.close() }
        
        var requestCount = 0
        let maxRequests = 100
        
        // Keep-alive connection loop
        while requestCount < maxRequests {
            requestCount += 1
            
            // Read request with timeout
            guard let httpRequest = await readHttpRequestWithTimeout(clientSocket, timeout: 30) else {
                // Timeout or connection closed by client
                break
            }
            
            let requestContext = HttpRequestContext(
                method: httpRequest.method,
                path: httpRequest.path,
                fullPath: httpRequest.fullPath,
                timestamp: Date()
            )
            
            do {
                try await beforeHook?(requestContext)
            } catch {
                print("Error in beforeResponseHook: \(error)")
            }
            
            let response: HttpResponse
            
            if httpRequest.method != "GET" {
                response = HttpResponse(statusCode: 405, contentType: "text/plain", 
                                      data: "405 Method Not Allowed".data(using: .utf8) ?? Data())
            } else {
                response = serveFile(path: httpRequest.path, servePath: servePath)
            }
            
            // Send response
            clientSocket.send(response.generateResponseString())
            clientSocket.send(response.data)
            
            logRequestStatic(httpRequest.method, httpRequest.fullPath, response.statusCode)
            await afterHook?(requestContext, response.statusCode)
            
            // Check if client wants to close connection
            if httpRequest.shouldClose {
                break
            }
        }
    }
    
    private static func readHttpRequestWithTimeout(_ socket: Socket, timeout: TimeInterval) async -> HttpRequest? {
        return await withTaskGroup(of: HttpRequest?.self) { group in
            // Add timeout task
            group.addTask {
                try? await Task.sleep(for: .seconds(timeout))
                return nil
            }
            
            // Add read task
            group.addTask {
                return readHttpRequest(socket)
            }
            
            // Return first result (either request or timeout)
            guard let result = await group.next() else { return nil }
            group.cancelAll()
            return result
        }
    }
    
    private static func readHttpRequest(_ socket: Socket) -> HttpRequest? {
        var buffer = Data()
        let chunkSize = 1024
        
        // Read until we have complete HTTP headers (until \r\n\r\n)
        while true {
            var chunk = [UInt8](repeating: 0, count: chunkSize)
            let bytesRead = socket.recv(&chunk, chunkSize)
            
            if bytesRead <= 0 {
                return nil // Connection closed or error
            }
            
            buffer.append(contentsOf: chunk[0..<bytesRead])
            
            // Check if we have complete headers
            if let headerEnd = buffer.range(of: "\r\n\r\n".data(using: .utf8)!) {
                // We have complete headers, parse the request
                let headerData = buffer[..<headerEnd.lowerBound]
                guard let headerString = String(data: headerData, encoding: .utf8) else {
                    return nil
                }
                
                return parseHttpRequest(headerString)
            }
            
            // Prevent infinite buffer growth
            if buffer.count > 8192 { // 8KB limit for headers
                return nil
            }
        }
    }
    
    private static func parseHttpRequest(_ headerString: String) -> HttpRequest? {
        let lines = headerString.components(separatedBy: "\r\n")
        guard !lines.isEmpty else { return nil }
        
        // Parse request line (e.g., "GET /path HTTP/1.1")
        let requestLine = lines[0].components(separatedBy: " ")
        guard requestLine.count >= 3 else { return nil }
        
        let method = requestLine[0]
        let fullPath = requestLine[1]
        let httpVersion = requestLine[2]
        let path = fullPath.components(separatedBy: "?").first ?? fullPath
        
        // Parse headers
        var headers: [String: String] = [:]
        for line in lines[1...] {
            if line.isEmpty { break }
            let parts = line.components(separatedBy: ": ")
            if parts.count >= 2 {
                let key = parts[0].lowercased()
                let value = parts[1...].joined(separator: ": ")
                headers[key] = value
            }
        }
        
        return HttpRequest(method: method, path: path, fullPath: fullPath, 
                          httpVersion: httpVersion, headers: headers)
    }



    private static func serveFile(path: String, servePath: String) -> HttpResponse {
        var filePath = path == "/" ?
            servePath + "/index.html" :
            path.hasSuffix("/") ? servePath + path + "index.html" :
            servePath + path

        // If not a regular file, try directory index serving
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory) || isDirectory.boolValue {
            let indexPath = filePath + "/index.html"
            if FileManager.default.fileExists(atPath: indexPath) {
                filePath = indexPath
            }
        }

        guard filePath.hasPrefix(servePath),
              FileManager.default.fileExists(atPath: filePath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            return HttpResponse(statusCode: 404, contentType: "text/plain", 
                               data: "404 Not Found".data(using: .utf8) ?? Data())
        }

        let contentType = filePath.hasSuffix(".html") ? "text/html; charset=utf-8" :
                         filePath.hasSuffix(".css") ? "text/css" :
                         filePath.hasSuffix(".js") ? "application/javascript" :
                         filePath.hasSuffix(".json") ? "application/json" :
                         filePath.hasSuffix(".png") ? "image/png" :
                         filePath.hasSuffix(".jpg") || filePath.hasSuffix(".jpeg") ? "image/jpeg" :
                         filePath.hasSuffix(".gif") ? "image/gif" :
                         filePath.hasSuffix(".webp") ? "image/webp" :
                         filePath.hasSuffix(".svg") ? "image/svg+xml" :
                         filePath.hasSuffix(".ico") ? "image/x-icon" :
                         filePath.hasSuffix(".txt") ? "text/plain" :
                         filePath.hasSuffix(".xml") ? "application/xml" :
                         "application/octet-stream"

        return HttpResponse(statusCode: 200, contentType: contentType, data: data)
    }


    private static func logRequestStatic(_ method: String, _ path: String, _ statusCode: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("\(timestamp) \(method) \(path) \(statusCode)")
    }

}

public enum TinyHttpServerError: Error {
    case socketCreationFailed, bindFailed, listenFailed
}
