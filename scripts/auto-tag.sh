#!/usr/bin/env bash

set -euo pipefail

# Auto-tag script for version bumps
# Creates a git tag based on the current version found in package.json or Sources/Command/Command.swift

extract_swift_version() {
  local file="$1"
  sed -n 's/.*version: \"\([^"]\+\)\".*/\1/p' "$file" | head -n1 || true
}

get_current_version() {
  local v=""
  if [[ -f package.json ]] && command -v jq >/dev/null 2>&1; then
    v=$(jq -r '.version' package.json 2>/dev/null || true)
  elif [[ -f Sources/Command/Command.swift ]]; then
    v=$(extract_swift_version Sources/Command/Command.swift)
  fi
  printf "%s" "$v"
}

is_valid_semver() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]
}

tag_exists() {
  git rev-parse -q --verify "refs/tags/$1" >/dev/null
}

create_and_push_tag() {
  local version="$1"
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  git tag "$version"
  git push origin "$version"
}

main() {
  local version
  version=$(get_current_version)

  if [[ -z "$version" ]]; then
    echo "No version found; skipping."
    exit 1
  fi

  if ! is_valid_semver "$version"; then
    echo "Version '$version' is not semver; skipping."
    exit 1
  fi

  if tag_exists "$version"; then
    echo "Tag '$version' already exists; skipping."
    exit 1
  fi

  create_and_push_tag "$version"

  # Output for GitHub Actions
  echo "created_tag=${version}" >> $GITHUB_OUTPUT
  echo "Created tag ${version}"
}

main "$@"