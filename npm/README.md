@ainame/tuzuru (npm)

NPM wrapper for the Tuzuru static blog generator.

What it does
- Installs prebuilt Tuzuru binary for your platform (macOS universal or Linux x64/aarch64) during npm install.
- Exposes a `tuzuru` executable on your PATH.
- Sets `TUZURU_RESOURCES` automatically so Tuzuru can locate its resource bundle.

Install
- Latest published: `npm i -g @ainame/tuzuru`
- Or as a dev dependency: `npm i -D @ainame/tuzuru`

Usage
- `tuzuru --help`
- `tuzuru generate`
- `tuzuru init`

Version mapping
- The npm package version should match the Tuzuru GitHub release tag (no `v` prefix). The installer fetches the asset for that tag.
- If the package version is `0.0.0`, the installer falls back to the latest release via the GitHub API.

Maintainers: how to publish
1) Create a Tuzuru release and note the version (e.g. `1.2.3`). Ensure assets exist named:
   - `tuzuru-1.2.3-macos-universal.tar.gz`
   - `tuzuru-1.2.3-linux-x86_64.tar.gz`
   - `tuzuru-1.2.3-linux-aarch64.tar.gz`
2) Update `npm/package.json` version to the same `1.2.3`.
3) From the `npm/` directory, run:
   - `npm publish --access public`

CI note
- This package uses the GitHub REST API unauthenticated during installation to resolve the asset URL. On heavily parallelized CI, consider setting `GITHUB_TOKEN` in the environment to increase rate limits.

