import Foundation

// Platform imports and aliases concentrated here so implementation
// types can avoid per-method conditional branches.
#if canImport(Darwin)
import Darwin
private let SOCK_STREAM_VALUE: Int32 = SOCK_STREAM
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> Int32 { socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: Int32, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: Int32, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { bind(s, addr, len) }
@inline(__always) private func clisten(_ s: Int32, _ backlog: Int32) -> Int32 { listen(s, backlog) }
@inline(__always) private func caccept(_ s: Int32, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> Int32 { accept(s, addr, len) }
@inline(__always) private func crecv(_ s: Int32, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: Int32, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: Int32) { close(s) }
#elseif canImport(Musl)
import Musl
private let SOCK_STREAM_VALUE: Int32 = SOCK_STREAM
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> Int32 { Musl.socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: Int32, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { Musl.setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: Int32, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { Musl.bind(s, addr, len) }
@inline(__always) private func clisten(_ s: Int32, _ backlog: Int32) -> Int32 { Musl.listen(s, backlog) }
@inline(__always) private func caccept(_ s: Int32, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> Int32 { Musl.accept(s, addr, len) }
@inline(__always) private func crecv(_ s: Int32, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { Musl.recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: Int32, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { Musl.send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: Int32) { Musl.close(s) }
#elseif canImport(Glibc)
import Glibc
private let SOCK_STREAM_VALUE: Int32 = Int32(SOCK_STREAM.rawValue)
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> Int32 { Glibc.socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: Int32, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { Glibc.setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: Int32, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { Glibc.bind(s, addr, len) }
@inline(__always) private func clisten(_ s: Int32, _ backlog: Int32) -> Int32 { Glibc.listen(s, backlog) }
@inline(__always) private func caccept(_ s: Int32, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> Int32 { Glibc.accept(s, addr, len) }
@inline(__always) private func crecv(_ s: Int32, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { Glibc.recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: Int32, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { Glibc.send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: Int32) { Glibc.close(s) }
#endif

// MARK: - Socket Abstraction

struct Socket {
    let fileDescriptor: Int32
    
    init(_ fileDescriptor: Int32) {
        self.fileDescriptor = fileDescriptor
    }
    
    func close() {
        cclose(fileDescriptor)
    }
    
    func recv(_ buffer: UnsafeMutablePointer<UInt8>, _ length: Int) -> Int {
        crecv(fileDescriptor, buffer, length, 0)
    }
    
    @discardableResult
    func send(_ buffer: UnsafeRawPointer?, _ length: Int) -> Int {
        csend(fileDescriptor, buffer, length, 0)
    }
    
    func sendData(_ data: Data) {
        _ = data.withUnsafeBytes {
            send($0.bindMemory(to: UInt8.self).baseAddress, data.count)
        }
    }
    
    func sendString(_ string: String) {
        let data = string.data(using: .utf8) ?? Data()
        sendData(data)
    }
}

// MARK: - Platform Implementation (simplified)

struct SocketAPI {
    static func createServerSocket(port: Int) throws -> Socket {
        let serverSocket = csocket(AF_INET, SOCK_STREAM_VALUE, 0)
        guard serverSocket != -1 else { throw TinyHttpServerError.socketCreationFailed }

        var reuseAddr: Int32 = 1
        // setsockopt expects a raw pointer; take address safely.
        withUnsafePointer(to: &reuseAddr) { ptr in
            _ = csetsockopt(
                serverSocket,
                SOL_SOCKET,
                SO_REUSEADDR,
                UnsafeMutableRawPointer(mutating: ptr),
                socklen_t(MemoryLayout<Int32>.size)
            )
        }

        var serverAddr = sockaddr_in()
        serverAddr.sin_family = sa_family_t(AF_INET)
        serverAddr.sin_port = in_port_t(port).bigEndian
        serverAddr.sin_addr.s_addr = INADDR_ANY

        let bindResult = withUnsafePointer(to: &serverAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                cbind(serverSocket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            cclose(serverSocket)
            throw TinyHttpServerError.bindFailed
        }

        guard clisten(serverSocket, 5) == 0 else {
            cclose(serverSocket)
            throw TinyHttpServerError.listenFailed
        }

        return Socket(serverSocket)
    }

    static func accept(_ serverSocket: Socket) -> Socket? {
        var clientAddr = sockaddr_in()
        var clientAddrSize = socklen_t(MemoryLayout<sockaddr_in>.size)
        let clientSocket = withUnsafeMutablePointer(to: &clientAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                caccept(serverSocket.fileDescriptor, $0, &clientAddrSize)
            }
        }
        return clientSocket != -1 ? Socket(clientSocket) : nil
    }

}
