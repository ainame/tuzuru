import Foundation

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
        \r

        """
    }
}

public typealias RequestHook = @Sendable (HttpRequestContext) async throws -> Void
public typealias ResponseHook = @Sendable (HttpRequestContext, Int) async -> Void
