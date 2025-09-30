#!/bin/bash
set -e

echo "🚀 Testing SwiftLint in container..."

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
container stop tuzuru-swiftlint 2>/dev/null || true
container delete tuzuru-swiftlint 2>/dev/null || true
sleep 2

# Start container system
echo "🔧 Starting container system..."
container system start

# Build SwiftLint container
echo "🐳 Building SwiftLint container..."
container build --tag swiftlint --file Dockerfile.swiftlint .

# Start container in background
echo "🚢 Starting SwiftLint container..."
container run --name tuzuru-swiftlint --detach --rm swiftlint sleep 600 &
sleep 3

# Copy source files to container
echo "📦 Copying source files to container..."
container exec tuzuru-swiftlint mkdir -p /workspace
for dir in Sources Tests Package.swift; do
    if [ -e "$dir" ]; then
        tar -cf - "$dir" | container exec -i tuzuru-swiftlint tar -xf - -C /workspace
    fi
done

# Run SwiftLint on the codebase
echo "🔍 Running SwiftLint on the codebase..."
echo ""

container exec tuzuru-swiftlint sh -c "cd /workspace && swiftlint"

echo ""
echo "✅ SwiftLint analysis complete!"

# Cleanup
echo "🧹 Stopping container..."
container stop tuzuru-swiftlint 2>/dev/null || true