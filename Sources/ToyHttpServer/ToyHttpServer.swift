import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Musl)
import Musl
#elseif canImport(Glibc)
import Glibc
#endif

/// A basic HTTP server with keep-alive support and Server-Sent Events for local development and testing purposes only.
///
/// Features:
/// - HTTP keep-alive connections (default behavior)
/// - 30-second connection timeout
/// - Maximum 100 requests per connection
/// - Basic GET request support for static files
/// - Server-Sent Events for live reload functionality
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

public class ToyHttpServer: @unchecked Sendable {
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
                    afterHook = self.afterResponseHook,
                ] in
                    await ToyHttpServer.handleClientInstance(
                        clientSocket,
                        servePath: servePath,
                        beforeHook: beforeHook,
                        afterHook: afterHook,
                    )
                }
            }
        }
    }

    private static func handleClientInstance(
        _ clientSocket: Socket,
        servePath: String,
        beforeHook: RequestHook?,
        afterHook: ResponseHook?,
    ) async {
        defer { clientSocket.close() }

        var requestCount = 0
        let maxRequests = 100

        // Keep-alive connection loop
        while requestCount < maxRequests {
            requestCount += 1

            // Read request with timeout
            guard let httpRequest = await HttpParser.readHttpRequestWithTimeout(clientSocket, timeout: 30) else {
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

    private static func logRequestStatic(_ method: String, _ path: String, _ statusCode: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("\(timestamp) \(method) \(path) \(statusCode)")
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

        let contentType = determineContentType(for: filePath)

        return HttpResponse(statusCode: 200, contentType: contentType, data: data)
    }

    private static func determineContentType(for filePath: String) -> String {
        return filePath.hasSuffix(".html") ? "text/html; charset=utf-8" :
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
    }
}

public enum TinyHttpServerError: Error {
    case socketCreationFailed, bindFailed, listenFailed
}
