#!/bin/bash
set -e

echo "🔨 Building Tuzuru for Linux with static Swift SDK..."
echo "📋 Using same commands as GitHub Actions release workflow..."

# Check if Swift static Linux SDK is available
if ! swift sdk list | grep -q "static-linux"; then
    echo "❌ Swift static SDK for Linux not found"
    echo "📥 Please install it first:"
    echo "   swift sdk install https://download.swift.org/swift-6.1.2-release/static-sdk/swift-6.1.2-RELEASE/swift-6.1.2-RELEASE_static-linux-0.0.1.artifactbundle.tar.gz --checksum df0b40b9b582598e7e3d70c82ab503fd6fbfdff71fd17e7f1ab37115a0665b3b"
    exit 1
fi

# Get current architecture (for Apple Silicon vs Intel)
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    SDK_ARCH="aarch64"
    echo "🍎 Detected Apple Silicon (arm64) - building for Linux aarch64"
else
    SDK_ARCH="x86_64"  
    echo "🖥️  Detected Intel (x86_64) - building for Linux x86_64"
fi

# Clean any previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build

# Build for Linux using the same command as GitHub Actions
echo "🔨 Building Linux ${SDK_ARCH} binary (same as GitHub Actions)..."
swift build -c release --swift-sdk ${SDK_ARCH}-swift-linux-musl

# Check if binary was created
BINARY_PATH=".build/${SDK_ARCH}-swift-linux-musl/release/tuzuru"
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Build failed - binary not found at $BINARY_PATH"
    exit 1
fi

# Check if resources were created
RESOURCES_PATH=".build/${SDK_ARCH}-swift-linux-musl/release/tuzuru_TuzuruLib.resources"
if [ ! -d "$RESOURCES_PATH" ]; then
    echo "❌ Build failed - resources not found at $RESOURCES_PATH"
    exit 1
fi

echo "✅ Build completed successfully!"
echo "📦 Binary: $BINARY_PATH"
echo "📁 Resources: $RESOURCES_PATH" 
echo "🏗️  Architecture: Linux ${SDK_ARCH}"
echo ""
echo "🐳 Use './scripts/test-linux-static.sh' to test with Docker"