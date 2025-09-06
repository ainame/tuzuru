#!/bin/bash

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: Invalid version format. Use semantic versioning (e.g., 1.0.0)"
    exit 1
fi

# Check git status
if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory is not clean. Please commit or stash your changes."
    exit 1
fi

echo "Updating version to $NEW_VERSION"

# Update version in Command.swift
sed -i '' "s/version: \".*\"/version: \"$NEW_VERSION\"/" Sources/Command/Command.swift

# Update version in Formula if it exists
if [ -f "Formula/tuzuru.rb" ]; then
    sed -i '' "s|download/[^/]*/|download/$NEW_VERSION/|" Formula/tuzuru.rb
    sed -i '' "s|tuzuru-[^-]*-macos|tuzuru-$NEW_VERSION-macos|" Formula/tuzuru.rb
fi

# Update npm package.json version to match tag (no git tag creation)
if command -v npm >/dev/null 2>&1; then
    (cd npm && npm version --no-git-tag-version "$NEW_VERSION")
else
    echo "Warning: npm is not installed; skipped updating npm/package.json version"
fi

# Build and test
echo "Building..."
swiftly run swift build

echo "Running tests..."
swiftly run swift test

# Commit and tag
git fetch
git add .
git commit -m "Bump version to $NEW_VERSION"
git tag "$NEW_VERSION"
git push origin main
git push origin "$NEW_VERSION"

echo "Release $NEW_VERSION completed. GitHub Actions will build artifacts and publish npm package."
