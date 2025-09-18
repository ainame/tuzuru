#!/bin/bash

set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 [--dry-run] [--token <github_token>]

Examples:
  $0 --dry-run
  $0 --token ghp_xxx

Environment variables:
  RELEASE_PLEASE_TOKEN  Personal access token with "contents"/"pull_requests" scopes.
  GITHUB_TOKEN          Fallback token if RELEASE_PLEASE_TOKEN is unset.
USAGE
}

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required tool '$1' is not installed."
    exit 1
  fi
}

ensure_clean_worktree() {
  if ! git diff-index --quiet HEAD --; then
    echo "Error: Working directory is not clean. Please commit or stash your changes."
    exit 1
  fi
}

main() {
  local dry_run=false
  local token_arg=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        dry_run=true
        shift
        ;;
      --token)
        token_arg="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
  done

  ensure_clean_worktree
  require_tool git
  require_tool npx
  require_tool swift

  local token="${token_arg:-${RELEASE_PLEASE_TOKEN:-${GITHUB_TOKEN:-}}}"
  if [[ -z "$token" ]]; then
    echo "Error: provide a GitHub token via --token, RELEASE_PLEASE_TOKEN, or GITHUB_TOKEN."
    exit 1
  fi

  echo "Running swift build/test before preparing release PR..."
  swift build
  swift test

  echo "Triggering release-please to open/update the release PR..."
  local args=(release-please release-pr \
    --repo-url=ainame/Tuzuru \
    --target-branch=main \
    --token="$token")
  if [[ "$dry_run" == true ]]; then
    args+=(--dry-run)
  fi

  npx --yes "${args[@]}"

  echo
  echo "release-please invoked. Review the PR in GitHub UI and merge once ready."
}

main "$@"
