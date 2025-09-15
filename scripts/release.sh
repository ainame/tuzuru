#!/bin/bash

set -euo pipefail

#
# Tuzuru release helper
#
# Creates a release branch and PR for version bump.
# After PR merge, release.yml workflow will create the tag automatically.
#
# Usage:
#   scripts/release.sh <version>
#
# Examples:
#   scripts/release.sh 1.2.3
#

usage() {
  cat <<USAGE
Usage:
  $0 <version>   Create a branch and PR to bump version

Examples:
  $0 1.2.3
USAGE
}

ensure_clean_worktree() {
  if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory is not clean. Please commit or stash your changes."
    exit 1
  fi
}

validate_semver() {
  local v="$1"
  if ! echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+)?$'; then
    echo "Error: Invalid version format. Use semantic versioning (e.g., 1.0.0 or 1.0.0-rc.1)"
    exit 1
  fi
}

update_sources_for_version() {
  local v="$1"

  echo "Updating version to $v"

  # Update version in Command.swift
  sed -i '' "s/version: \".*\"/version: \"$v\"/" Sources/Command/Command.swift


  # Update npm package.json version to match tag (no git tag creation)
  if command -v npm >/dev/null 2>&1; then
    npm version --no-git-tag-version "$v"
  else
    echo "Warning: npm is not installed; skipped updating package.json version"
  fi

  # Update internal composite actions to use the specific version of npm package
  echo "Updating GitHub composite actions to use @ainame/tuzuru@$v"
  sed -i '' "s/@ainame\/tuzuru@[^[:space:]]*/@ainame\/tuzuru@$v/g" .github/actions/tuzuru-generate/action.yml
  sed -i '' "s/@ainame\/tuzuru@[^[:space:]]*/@ainame\/tuzuru@$v/g" .github/actions/tuzuru-deploy/action.yml
}

build_and_test() {
  echo "Building..."
  if command -v swift >/dev/null 2>&1; then
    swift build
  elif command -v swiftly >/dev/null 2>&1; then
    swiftly run swift build
  else
    echo "Warning: neither 'swift' nor 'swiftly' found in PATH; skipping build"
  fi

  echo "Running tests..."
  if command -v swift >/dev/null 2>&1; then
    swift test
  elif command -v swiftly >/dev/null 2>&1; then
    swiftly run swift test
  else
    echo "Warning: neither 'swift' nor 'swiftly' found in PATH; skipping tests"
  fi
}

prepare_pr() {
  local v="$1"

  ensure_clean_worktree
  validate_semver "$v"

  # Ensure we are on main and up-to-date before branching
  git fetch origin
  git switch main
  git pull --ff-only origin main

  update_sources_for_version "$v"
  build_and_test

  local branch="release/${v}"
  git switch -c "$branch"
  git add .
  git commit -m "[Version Bump] bump version to $v"
  git push -u origin "$branch"

  if command -v gh >/dev/null 2>&1; then
    echo "Opening pull request via GitHub CLI..."
    gh pr create \
      --title "[Version Bump] $v" \
      --body "Bump version to $v

This PR was created by scripts/release.sh. After merge, the release workflow will automatically create the tag." \
      --base main \
      --head "$branch" || true
  else
    echo "GitHub CLI 'gh' not found. Please open a PR from branch '$branch' into 'main'."
  fi

  echo "Created branch $branch with version bump. Opened PR if possible."
}


main() {
  if [ $# -eq 0 ]; then
    usage
    exit 1
  fi

  # Check if argument looks like a version
  if echo "$1" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+'; then
    prepare_pr "$1"
  else
    usage
    exit 1
  fi
}

main "$@"
