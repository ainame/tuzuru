import Foundation

struct HttpParser {

    static func readHttpRequestWithTimeout(_ socket: Socket, timeout: TimeInterval) async -> HttpRequest? {
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

    static func readHttpRequest(_ socket: Socket) -> HttpRequest? {
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
            if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) {
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

    static func parseHttpRequest(_ headerString: String) -> HttpRequest? {
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
}
