// System framework exists on SDK and Subprocess depends on it conditionally.
// https://developer.apple.com/documentation/System
// https://github.com/swiftlang/swift-subprocess/issues/141

#if canImport(System)
@_exported import struct System.FilePath
public typealias FilePath = System.FilePath
#else
@_exported import struct SystemPackage.FilePath
public typealias FilePath = SystemPackage.FilePath
#endif
