import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// A very basic HTTP server for local development and testing purposes only.
///
/// WARNING: This is NOT a production-ready HTTP server and should never be used
/// in production environments. It lacks many essential features including:
/// - Security measures and input validation
/// - Proper error handling and recovery
/// - HTTP/1.1 compliance beyond basic GET requests
/// - Support for request headers, cookies, authentication
/// - Connection pooling and resource management
/// - Performance optimizations
///
/// This server is intended solely for serving static files during local development
/// of the Tuzuru static blog generator.

public class TinyHttpServer {
    private let port: Int
    private let servePath: String

    public init(port: Int, servePath: String) {
        self.port = port
        self.servePath = servePath
    }

    public func start() async throws {
        #if canImport(Darwin)
        let serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        #elseif canImport(Glibc)
        let serverSocket = socket(AF_INET, SOCK_STREAM.rawValue, 0)
        #endif
        guard serverSocket != -1 else { throw TinyHttpServerError.socketCreationFailed }

        var reuseAddr: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, socklen_t(MemoryLayout<Int32>.size))

        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = in_port_t(port).bigEndian
        serverAddr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &serverAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            close(serverSocket)
            throw TinyHttpServerError.bindFailed
        }

        guard listen(serverSocket, 5) == 0 else {
            close(serverSocket)
            throw TinyHttpServerError.listenFailed
        }

        print("🚀 Starting server on http://localhost:\(port)")
        print("📂 Serving directory: \(servePath)")
        print("⚠️  This is a basic development server - not for production use")
        print("🐛 Report issues at: https://github.com/ainame/Tuzuru/issues")
        print("🛑 Press Ctrl+C to stop")

        signal(SIGINT) { _ in exit(0) }

        let servePath = self.servePath
        await withTaskGroup(of: Void.self) { group in
            while true {
                var clientAddr = sockaddr_in()
                var clientAddrSize = socklen_t(MemoryLayout<sockaddr_in>.size)

                let clientSocket = withUnsafeMutablePointer(to: &clientAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        accept(serverSocket, $0, &clientAddrSize)
                    }
                }

                guard clientSocket != -1 else { continue }
                
                group.addTask {
                    TinyHttpServer.handleClientStatic(clientSocket, servePath: servePath)
                }
            }
        }
    }

    private static func handleClientStatic(_ clientSocket: Int32, servePath: String) {
        defer { close(clientSocket) }

        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = recv(clientSocket, &buffer, buffer.count, 0)
        guard bytesRead > 0,
              let request = String(bytes: buffer[0..<bytesRead], encoding: .utf8),
              let requestLine = request.components(separatedBy: "\r\n").first else {
            logRequestStatic("INVALID", "-", 400)
            return
        }

        let requestComponents = requestLine.components(separatedBy: " ")
        guard requestComponents.count >= 2 else {
            logRequestStatic("INVALID", "-", 400)
            return
        }

        let method = requestComponents[0]
        let fullPath = requestComponents[1]
        let path = fullPath.components(separatedBy: "?").first ?? fullPath

        guard method == "GET" else {
            logRequestStatic(method, fullPath, 405)
            sendStringStatic(clientSocket, "HTTP/1.1 405 Method Not Allowed\r\n\r\n405 Method Not Allowed")
            return
        }

        let statusCode = serveFileStatic(clientSocket, path: path, servePath: servePath)
        logRequestStatic(method, fullPath, statusCode)
    }

    private func serveFile(_ clientSocket: Int32, path: String) -> Int {
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
            sendString(clientSocket, "HTTP/1.1 404 Not Found\r\n\r\n404 Not Found")
            return 404
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

        let response = "HTTP/1.1 200 OK\r\nContent-Type: \(contentType)\r\nContent-Length: \(data.count)\r\n\r\n"
        sendString(clientSocket, response)
        _ = data.withUnsafeBytes {
            #if canImport(Darwin)
            Darwin.send(clientSocket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #elseif canImport(Glibc)
            Glibc.send(clientSocket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #endif
        }
        return 200
    }

    private func sendString(_ socket: Int32, _ string: String) {
        let data = string.data(using: .utf8) ?? Data()
        _ = data.withUnsafeBytes {
            #if canImport(Darwin)
            Darwin.send(socket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #elseif canImport(Glibc)
            Glibc.send(socket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #endif
        }
    }

    private func logRequest(_ method: String, _ path: String, _ statusCode: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("\(timestamp) \(method) \(path) \(statusCode)")
    }

    private static func serveFileStatic(_ clientSocket: Int32, path: String, servePath: String) -> Int {
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
            sendStringStatic(clientSocket, "HTTP/1.1 404 Not Found\r\n\r\n404 Not Found")
            return 404
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

        let response = "HTTP/1.1 200 OK\r\nContent-Type: \(contentType)\r\nContent-Length: \(data.count)\r\n\r\n"
        sendStringStatic(clientSocket, response)
        _ = data.withUnsafeBytes {
            #if canImport(Darwin)
            Darwin.send(clientSocket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #elseif canImport(Glibc)
            Glibc.send(clientSocket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #endif
        }
        return 200
    }

    private static func sendStringStatic(_ socket: Int32, _ string: String) {
        let data = string.data(using: .utf8) ?? Data()
        _ = data.withUnsafeBytes {
            #if canImport(Darwin)
            Darwin.send(socket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #elseif canImport(Glibc)
            Glibc.send(socket, $0.bindMemory(to: UInt8.self).baseAddress, data.count, 0)
            #endif
        }
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
