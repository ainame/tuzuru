#!/bin/bash
set -e

echo "🚀 Testing SwiftLint in container..."

# Start container system
echo "🔧 Starting container system..."
container system start

# Build SwiftLint container
echo "🐳 Building SwiftLint container..."
container build --tag swiftlint --file Dockerfile.swiftlint .

# Run SwiftLint on the codebase
echo "🔍 Running SwiftLint on the codebase..."
echo ""

container run --rm swiftlint

echo ""
echo "✅ SwiftLint analysis complete!"