#!/bin/bash
set -e

echo "🚀 Setting up Linux testing environment..."

# Clean up any existing containers
echo "🧹 Cleaning up existing containers..."
container stop tuzuru-test 2>/dev/null || true
container delete tuzuru-test 2>/dev/null || true
sleep 2

# Build and run the container with port forwarding
echo "🔧 Starting container system..."
container system start
echo "🐳 Building container from source..."
container build --tag tuzuru --file Dockerfile .
echo "🚢 Starting container with port forwarding..."
container run --name tuzuru-test --detach --rm --publish 8080:8080 tuzuru sleep 3600 &
sleep 5

# Initialize blog
echo "🏗️  Initializing blog..."
container exec tuzuru-test tuzuru init

# Create sample content
echo "📝 Creating sample content..."
container exec tuzuru-test bash -c 'cat > contents/sample-post.md << EOF
---
title: "Sample Post"
author: "Test Author"
publishedAt: "2023-01-01"
---

# Sample Post

This is a test post running on Linux, accessible from macOS!

## Features Tested

- Cross-platform compatibility
- Apple Container port forwarding
- Live development server

Access this from your macOS browser at: http://localhost:8080
EOF'

container exec tuzuru-test bash -c 'cat > contents/about.md << EOF
---
title: "About"
author: "Test Author"
publishedAt: "2023-01-02"
---

# About This Site

This blog is running inside a Linux container using Apple Container,
but served to macOS via port forwarding.

Pretty cool, right?
EOF'

# Commit initial content
container exec tuzuru-test git add .
container exec tuzuru-test git commit -m "Initial blog content"

# Generate the blog
echo "🔄 Generating blog..."
container exec tuzuru-test tuzuru generate

echo ""
echo "🎉 Blog setup complete!"
echo ""
echo "📡 Starting server at: http://localhost:8080"
echo "🔧 Server running with real-time logs (Ctrl+C to stop):"
echo ""

# Start the server (this will run until interrupted)
container exec tuzuru-test stdbuf -oL -eL tuzuru serve --port 8080
