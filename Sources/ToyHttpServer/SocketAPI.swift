// swiftlint:disable identifier_name type_name
// This file wraps low-level C socket APIs and requires platform-specific code
import Foundation

// Platform imports and aliases concentrated here so implementation
// types can avoid per-method conditional branches.
#if canImport(Darwin)
import Darwin
typealias SocketDescriptor = Int32
private let INVALID_SOCKET_VALUE: SocketDescriptor = -1
private let SOCK_STREAM_VALUE: Int32 = SOCK_STREAM
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> SocketDescriptor { socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: SocketDescriptor, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: SocketDescriptor, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { bind(s, addr, len) }
@inline(__always) private func clisten(_ s: SocketDescriptor, _ backlog: Int32) -> Int32 { listen(s, backlog) }
@inline(__always) private func caccept(_ s: SocketDescriptor, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> SocketDescriptor { accept(s, addr, len) }
@inline(__always) private func crecv(_ s: SocketDescriptor, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: SocketDescriptor, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: SocketDescriptor) { close(s) }
#elseif canImport(Musl)
import Musl
typealias SocketDescriptor = Int32
private let INVALID_SOCKET_VALUE: SocketDescriptor = -1
private let SOCK_STREAM_VALUE: Int32 = SOCK_STREAM
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> SocketDescriptor { Musl.socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: SocketDescriptor, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { Musl.setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: SocketDescriptor, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { Musl.bind(s, addr, len) }
@inline(__always) private func clisten(_ s: SocketDescriptor, _ backlog: Int32) -> Int32 { Musl.listen(s, backlog) }
@inline(__always) private func caccept(_ s: SocketDescriptor, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> SocketDescriptor { Musl.accept(s, addr, len) }
@inline(__always) private func crecv(_ s: SocketDescriptor, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { Musl.recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: SocketDescriptor, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { Musl.send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: SocketDescriptor) { Musl.close(s) }
#elseif canImport(Glibc)
import Glibc
typealias SocketDescriptor = Int32
private let INVALID_SOCKET_VALUE: SocketDescriptor = -1
private let SOCK_STREAM_VALUE: Int32 = Int32(SOCK_STREAM.rawValue)
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> SocketDescriptor { Glibc.socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: SocketDescriptor, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 { Glibc.setsockopt(s, level, name, value, len) }
@inline(__always) private func cbind(_ s: SocketDescriptor, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 { Glibc.bind(s, addr, len) }
@inline(__always) private func clisten(_ s: SocketDescriptor, _ backlog: Int32) -> Int32 { Glibc.listen(s, backlog) }
@inline(__always) private func caccept(_ s: SocketDescriptor, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> SocketDescriptor { Glibc.accept(s, addr, len) }
@inline(__always) private func crecv(_ s: SocketDescriptor, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int { Glibc.recv(s, buf, len, flags) }
@inline(__always) private func csend(_ s: SocketDescriptor, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int { Glibc.send(s, buf, len, flags) }
@inline(__always) private func cclose(_ s: SocketDescriptor) { Glibc.close(s) }
#elseif canImport(WinSDK)
import WinSDK

typealias SocketDescriptor = SOCKET
typealias sa_family_t = ADDRESS_FAMILY
typealias in_port_t = USHORT
typealias in_addr = IN_ADDR
typealias sockaddr = SOCKADDR
typealias sockaddr_in = SOCKADDR_IN
private let INVALID_SOCKET_VALUE: SocketDescriptor = WinSDK.INVALID_SOCKET
private let SOCK_STREAM_VALUE: Int32 = Int32(SOCK_STREAM)
@inline(__always) private func csocket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> SocketDescriptor { WinSDK.socket(domain, type, proto) }
@inline(__always) private func csetsockopt(_ s: SocketDescriptor, _ level: Int32, _ name: Int32, _ value: UnsafeMutableRawPointer?, _ len: socklen_t) -> Int32 {
    WinSDK.setsockopt(s, level, name, value?.assumingMemoryBound(to: CHAR.self), Int32(len))
}
@inline(__always) private func cbind(_ s: SocketDescriptor, _ addr: UnsafePointer<sockaddr>!, _ len: socklen_t) -> Int32 {
    WinSDK.bind(s, addr, Int32(len))
}
@inline(__always) private func clisten(_ s: SocketDescriptor, _ backlog: Int32) -> Int32 { WinSDK.listen(s, backlog) }
@inline(__always) private func caccept(_ s: SocketDescriptor, _ addr: UnsafeMutablePointer<sockaddr>?, _ len: UnsafeMutablePointer<socklen_t>?) -> SocketDescriptor {
    WinSDK.accept(s, addr, len)
}
@inline(__always) private func crecv(_ s: SocketDescriptor, _ buf: UnsafeMutablePointer<UInt8>!, _ len: Int, _ flags: Int32) -> Int {
    buf.withMemoryRebound(to: CChar.self, capacity: len) {
        Int(WinSDK.recv(s, $0, Int32(len), flags))
    }
}
@inline(__always) private func csend(_ s: SocketDescriptor, _ buf: UnsafeRawPointer?, _ len: Int, _ flags: Int32) -> Int {
    Int(WinSDK.send(s, buf?.assumingMemoryBound(to: CChar.self), Int32(len), flags))
}
@inline(__always) private func cclose(_ s: SocketDescriptor) { _ = WinSDK.closesocket(s) }
#else
#error("Unsupported platform")
#endif

// MARK: - Socket Abstraction

struct Socket {
    let fileDescriptor: SocketDescriptor

    init(_ fileDescriptor: SocketDescriptor) {
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

    func send(_ data: Data) {
        _ = data.withUnsafeBytes {
            send($0.bindMemory(to: UInt8.self).baseAddress, data.count)
        }
    }

    func send(_ string: String) {
        let data = string.data(using: .utf8) ?? Data()
        send(data)
    }

    static func createServerSocket(port: Int) throws -> Socket {
        #if canImport(WinSDK)
        try Winsock.ensureInitialized()
        #endif
        let serverSocket = csocket(AF_INET, SOCK_STREAM_VALUE, 0)
        guard serverSocket != INVALID_SOCKET_VALUE else { throw TinyHttpServerError.socketCreationFailed }

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
        #if canImport(WinSDK)
        serverAddr.sin_addr.S_un.S_addr = INADDR_ANY
        #else
        serverAddr.sin_addr.s_addr = INADDR_ANY
        #endif

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
        return clientSocket != INVALID_SOCKET_VALUE ? Socket(clientSocket) : nil
    }
}

#if canImport(WinSDK)
private enum Winsock {
    private static let requestedVersion: WORD = WORD(0x0202)

    private static let startupResult: Int32 = {
        var data = WSADATA()
        return WinSDK.WSAStartup(requestedVersion, &data)
    }()

    static func ensureInitialized() throws {
        guard startupResult == 0 else {
            throw TinyHttpServerError.socketCreationFailed
        }
    }
}
#endif
