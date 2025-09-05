#!/bin/bash
set -e

echo "🚀 Testing Tuzuru with pre-built static Linux binary..."

# Check if static binary exists (look for arch-specific build directories)
BINARY_FOUND=false
for BUILD_DIR in .build/*-swift-linux-musl/release; do
    if [ -f "$BUILD_DIR/tuzuru" ]; then
        BINARY_FOUND=true
        break
    fi
done

if [ "$BINARY_FOUND" = false ]; then
    echo "❌ Static Linux binary not found"
    echo "🔨 Run './scripts/build-linux-static.sh' first"
    exit 1
fi

# Clean up any existing container
echo "🧹 Cleaning up existing containers..."
container stop tuzuru-static-test 2>/dev/null || true
container delete tuzuru-static-test 2>/dev/null || true
sleep 2

# Build lightweight container with pre-built binary
echo "🐳 Building lightweight container with static binary..."
container build --tag tuzuru-static --file Dockerfile.static .

# Start container with port forwarding
echo "🚢 Starting container with port forwarding..."
container run --name tuzuru-static-test --detach --rm --publish 8080:8080 tuzuru-static sleep 3600 &
sleep 3

# Initialize blog
echo "🏗️  Initializing blog..."
container exec tuzuru-static-test tuzuru init

# Create sample content
echo "📝 Creating sample content..."
container exec tuzuru-static-test bash -c 'cat > contents/static-test.md << EOF
---
title: "Static Binary Test"
author: "Test User"
publishedAt: "2023-01-01"
---

# Static Binary Test

This blog is running from a static Linux binary built on macOS!

## Performance Benefits

- ⚡ No compilation time in Docker
- 🪶 Lightweight container (Ubuntu base)
- 🚀 Faster startup times
- 📦 Smaller image size

Built with Swift 6.1.2 static Linux SDK.
EOF'

# Commit content
container exec tuzuru-static-test git add .
container exec tuzuru-static-test git commit -m "Static binary test content"

# Generate blog
echo "🔄 Generating blog..."
container exec tuzuru-static-test tuzuru generate

echo ""
echo "🎉 Static binary test setup complete!"
echo ""
echo "📡 Starting server at: http://localhost:8080"
echo "🔧 Server running with real-time logs (Ctrl+C to stop):"
echo ""

# Start server with real-time logs in foreground
container exec tuzuru-static-test stdbuf -oL -eL tuzuru serve --port 8080