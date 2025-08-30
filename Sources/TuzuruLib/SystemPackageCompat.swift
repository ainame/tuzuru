// System package exists from SDK and Subprocess depends on this
// https://github.com/swiftlang/swift-subprocess/issues/141

#if canImport(System)
@_exported import struct System.FilePath
public typealias FilePath = System.FilePath
#else
@_exported import struct SystemPackage.FilePath
public typealias FilePath = SystemPackage.FilePath
#endif
