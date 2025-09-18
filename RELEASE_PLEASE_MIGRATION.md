# Release Please Migration Plan

## Summary
- Replace the hand-rolled release scripts/workflows with [`release-please`](https://github.com/googleapis/release-please) so version bumps always land through a PR and tags are generated from the merge commit.
- Keep version strings synchronized across Swift CLI (`Sources/Command/Command.swift`), npm package (`package.json`), and GitHub composite actions while still publishing tgz/zip binaries and npm packages from CI.
- Trigger binary builds, release asset uploads, npm publish, and Homebrew formula automation off the GitHub release that `release-please` creates, ensuring tags remain plain semver (no `v` prefix).

## Current State (Problem Summary)
- `scripts/release.sh` drives version bumps: it edits files locally, commits `[Version Bump]` on a release branch, and pushes a PR.
- `.github/workflows/release.yml` only runs after a merge to `main` **and** a `[Version Bump]` commit, then creates the tag, builds macOS + Linux artifacts, updates `Formula/tuzuru.rb`, and publishes to npm.
- Formula updates happen inside the same workflow, with an auto-generated branch + PR that is merged automatically—hard to audit and occasionally brittle.
- Manual discipline is required (running the script, keeping commit messages exact, cleaning the working tree), and rollbacks are difficult when any step fails mid-way.

## Target Requirements (from request)
- All releases cut from GitHub PRs merged to `main`; no direct pushes.
- Tags must be plain `MAJOR.MINOR.PATCH` (no `v` prefix) and drive GitHub Releases.
- Version strings updated in `Sources/Command/Command.swift`, `package.json`, and `Formula/tuzuru.rb` (formula update may trail because it needs final SHA256).
- Release artifacts: macOS universal binary + bundle, Linux x86_64 + aarch64 tarballs, checksums, npm package, release notes.
- Consider automating Homebrew tap updates via `brew bump-formula-pr` once release assets exist.

## Proposed Future Flow
1. **release-please PR generation**
   - New workflow (`release-please.yml`) runs on `workflow_dispatch`, nightly schedule, and optionally when pushing to `main` to surface pending releases.
   - Action config uses `include-v-in-tag: false`, a `node` release type (so `package.json` is handled) plus `extra-files` rules for Swift source and composite actions.
   - Release PR contains changelog, version bumps, and tests are exercised via normal PR checks.
2. **Merge & automatic tagging**
   - When the release PR merges, release-please automatically opens a GitHub Release, creates the `MAJOR.MINOR.PATCH` tag, and publishes release notes.
3. **Artifact builder workflow** (`release-assets.yml`)
   - Trigger: `release` event (`types: [published]`).
   - Runs matrix builds for Linux targets (cross compiled with `swiftly` static SDK) and a macOS universal build; because we rely on the static Linux SDK + musl, the host OS choice is flexible (macOS runner is fine).
   - Executes `swift build`/`swift test`, packages binaries/bundles, and uploads assets + checksum files to the existing GitHub Release (using `gh release upload`).
   - Publishes npm package with the release version (asserting the tag matches `package.json`).
4. **Formula updater workflow** (`homebrew-formula.yml`)
   - Triggered after binaries upload (either by `release-assets` dispatching a repository_dispatch or by listening for the same `release` event but depends on artifacts).
   - Uses `brew bump-formula-pr --url ... --sha256 ... --no-audit --no-bottle` to open a PR against this repo’s `Formula/` directory or external tap.
   - Requires a PAT with push/PR rights to the formula repository (`HOMEBREW_GITHUB_API_TOKEN`).
5. **Documentation & developer guidance**
   - Update `AGENTS.md` / README with the new “How to cut a release” instructions (run workflow dispatch, review release PR, merge).
   - Deprecate or repurpose `scripts/release.sh` (e.g., make it run `npx release-please release-pr --dry-run` for local preview).

## Implementation Checklist

### 1. Introduce release-please configuration
- Add `.release-please-manifest.json` with the current version (`{".": "0.3.3"}`) to seed state.
- Add `release-please-config.json` containing:
  - `include-v-in-tag: false`, `pull-request-title-pattern`, `changelog-sections` (optional customization).
  - `packages` entry for `.` using `release-type: node` (manages `package.json`) with `prerelease: false` to keep the channel single-track.
  - `extra-files` definitions:
    - `Sources/Command/Command.swift` (`regex` update for `version: "(?<version>[^"]+)"`).
    - `.github/actions/tuzuru-generate/action.yml` & `.github/actions/tuzuru-deploy/action.yml` (`@ainame/tuzuru@{version}`).
    - Any other hardcoded version references (docs/scripts if desired).
- (Optional) Add `plugins`: `sentence-case` commit messages, `linked-queries` for grouped components if we later split libraries/packages.

### 2. Create release-please GitHub Action
- `release-please.yml` job using `googleapis/release-please-action@v4` with inputs: `command: release-pr`, `token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}`.
- Configure triggers:
  - `workflow_dispatch` (manual release trigger).
  - `schedule` (e.g., daily) to automatically raise PRs even if nobody manually triggers.
  - Optional `push` to `main` to immediately offer a PR after feature merges (ensure concurrency to avoid duplicate jobs).
- Enable automerge by default so release PRs merge as soon as required checks (build/test/linters) succeed; document how to opt-out when a manual review is desired.
- Add instructions in PR template to run `swift test` before merging.

### 3. Replace the legacy release workflow
- Delete/rename `.github/workflows/release.yml` once new flow is validated.
- New `release-assets.yml` (macOS host) steps:
  1. Checkout (`fetch-depth: 0` to access tags).
  2. Load release version from `${{ github.event.release.tag_name }}`.
  3. Setup toolchain (Xcode 16.4, `swiftly` for Linux SDK, caches more aggressively).
  4. Run `swift build`/`swift test` for host before cross compilation.
  5. Build cross targets, package tarballs + resource bundles.
  6. Store artifacts (Actions artifacts for debugging + `gh release upload`).
  7. Publish npm package using `NODE_AUTH_TOKEN` (fail fast if tag mismatches `package.json`).
- Ensure workflow is idempotent—re-running should overwrite release assets (`gh release upload --clobber`).
- Always build full assets on release events because we only ship stable tags (no prerelease branch flow).

### 4. Automate Homebrew formula updates
- New workflow triggered after `release-assets` completes:
  - Use `actions/download-artifact` (if sharing artifacts) or the public release tarball to compute SHA.
  - `brew bump-formula-pr --force --no-browse --message "chore: bump tuzuru to ${version}" Formula/tuzuru.rb`.
  - Auto-merge the resulting PR (consistent with release PR policy) once brew CI checks clear.
- Keep `Formula/tuzuru.rb` in this repo; automation complexity stays manageable because `brew bump-formula-pr` works against local files—no extra tap permissions required.
- Add PAT with `public_repo` scope as `HOMEBREW_GITHUB_API_TOKEN`.
- Document fallback instructions for manual formula tweaks if automation fails.
- Note in docs that the formula PR may lag slightly because it needs the release tarball SHA (expected behaviour).

### 5. Update ancillary tooling & docs
- Rework `scripts/release.sh` to:
  - Validate clean tree, then call `npx release-please release-pr --repo-url=ainame/Tuzuru --token=$GITHUB_TOKEN` for local smoke testing.
  - Or convert it into a helper that just outputs how to trigger the CI-based release.
- Update `README.md` / `AGENTS.md` / `CLAUDE.md` with the new release steps and link to the new workflows.
- Remove references to `[Version Bump]` commit messages throughout the repo.

### 6. Secrets & permissions audit
- Confirm required secrets exist:
  - `NPM_TOKEN` (already used; ensure still scoped to publish).
  - `RELEASE_PLEASE_TOKEN` (optional; default `GITHUB_TOKEN` usually sufficient, but PAT recommended if repo has branch protections requiring workflow to bypass checks).
  - `HOMEBREW_GITHUB_API_TOKEN` for formula PRs.
- Ensure branch protection allows GitHub Actions to push tags/releases (release-please uses the token to create tags/releases).
- Verify runner availability (`macos-14` or `macos-13` might be more available than `macos-26`).

### 7. Dry run & rollout plan
- Run `npx release-please release-pr --dry-run` locally to confirm file updates.
- Push configuration to a feature branch, trigger `release-please` via `workflow_dispatch`, and inspect the generated PR.
- Once satisfied, archive the old workflow/scripts and merge the migration.
- Conduct a full patch release (e.g. `0.3.4`) as a smoke test once automation lands, since we are not maintaining separate prerelease channels.

## Follow-up Decisions
- Stick to a single stable channel; release-please will not manage `alpha/beta/rc` streams.
- Retain `Formula/tuzuru.rb` inside this repository—`brew bump-formula-pr` can update it in-place with minimal extra automation.
- Enable automerge for release PRs (and formula PRs) once required checks succeed, matching the goal of hands-off releases.
- Continue building Linux binaries via the static Linux SDK + musl toolchain; the host runner may remain macOS as long as we keep the cross-compile toolchain.

## References
- DeepWiki: [googleapis/release-please](https://deepwiki.com/googleapis/release-please), [googleapis/release-please-action](https://deepwiki.com/googleapis/release-please-action)
- GitHub Action: https://github.com/googleapis/release-please-action
- Homebrew PR automation: https://docs.brew.sh/How-To-Open-a-Homebrew-Pull-Request
