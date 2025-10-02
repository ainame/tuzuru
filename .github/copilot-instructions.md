# Copilot Instructions for Tuzuru

This file provides guidance to GitHub Copilot when reviewing code in this repository.

## Project Overview

Tuzuru is a static blog generator CLI tool written in Swift that converts markdown files to HTML pages using Mustache templates. It's designed for Swift 6.1 with macOS v15+ minimum requirement.

**Important**: The codebase includes conditional support for Linux (Glibc/Musl) and CI exercises the core targets on Windows, so always keep cross-platform compatibility and Windows path semantics in mind when reviewing code.

## Architecture

### Package Structure
- **Command target**: CLI interface using ArgumentParser with MainActor isolation
- **TuzuruLib target**: Core library containing business logic with Resources (Mustache templates and static assets)
- **ToyHttpServer target**: Minimal HTTP server for local development (used by `preview` command)

### Key Dependencies
- swift-argument-parser: CLI parsing
- swift-mustache: Template rendering
- swift-markdown: Markdown processing
- swift-system: File system operations
- swift-subprocess: Process execution
- Yams: YAML parsing

### Core Components
- `Sources/Command/Command.swift`: CLI command definitions using ArgumentParser
- `Sources/TuzuruLib/Tuzuru.swift`: Main facade that commands interact with
- `Sources/TuzuruLib/Configuration/`: Configuration management
- `Sources/TuzuruLib/Generator/`: HTML generation logic
- `Sources/TuzuruLib/SourceLoader/`: Content loading and parsing
- `Sources/TuzuruLib/Importer/`: Content import functionality
- `Sources/TuzuruLib/Amender/`: File metadata amending functionality
- `Sources/TuzuruLib/Initializer/`: Blog bootstrap and resource copy logic
- `Sources/TuzuruLib/Utils/`: Utilities including `FileManagerWrapper`, `GitWrapper`, `ChangeDetector`
- `Sources/ToyHttpServer/`: Local HTTP server implementation

## Swift Conventions

### Code Style
- Swift 6.1 features enabled
- MainActor isolation for Command target
- Public interfaces for library components
- Dependency injection pattern (e.g., FileManager injection)
- Async/await for command execution
- **CRITICAL**: Default values for configuration structs must be defined in `BlogConfiguration+DefaultValues.swift`, NEVER inline in the decoder methods

### Naming
- Structs: PascalCase (MainCommand, GenerateCommand)
- Properties/Methods: camelCase with descriptive names
- Use descriptive method names like `loadSources(_:)`, `generate(_:)`

### File Operations
- Use `FileManagerWrapper` instead of `FileManager.default` to support swift-testing and async/await APIs
- `FileManagerWrapper` uses `FilePath` as the primary type instead of URL or String path
- Always inject `FileManagerWrapper` from upstream code when possible
- When working with Subprocess or GitWrapper, use `FileManagerWrapper.workingDirectory` to ensure commands run in the correct location
- This is essential for testing with swift-testing's parallel execution via `GitRepositoryFixtureTrait`

### Windows Support
- **CRITICAL**: The CLI and library must compile and pass tests on Windows, Apple, and Linux platforms
- Never manipulate file paths with hard-coded `/` separators (e.g., `somePath.string.split(separator: "/")`)
- Use `FilePath` APIs such as `components`, `appending`, and `removingLastComponent()` for portable path operations
- Converting a string literal into a `FilePath` first is acceptable when deriving components

## Testing

### Unit Testing
- Use swift-testing (Testing) framework
- Create minimum test cases covering happy-path + important edge cases
- Tests run in parallel, so use fixtures properly

### E2E Testing (blog generation)
- Use `./tmp` directory with git (tuzuru commands depend on a git project)
- Don't delete `./tmp` directory

## Key Commands

### Development
- `swift build` - Build the project
- `swift run tuzuru` - Run the CLI tool
- `swift test` - Run all tests
- `swift test --parallel` - Run tests in parallel

### CLI Commands
- `swift run tuzuru generate` - Generate static blog (default command)
- `swift run tuzuru init` - Initialize a blog project
- `swift run tuzuru import` - Import posts from Hugo or Jekyll projects
- `swift run tuzuru amend` - Update publishedAt date and/or author for a markdown file
- `swift run tuzuru list` - List blog posts with metadata in CSV format
- `swift run tuzuru preview` - Start local HTTP server with auto-regeneration
- `swift run tuzuru --help` - Show help

## Important Patterns

### Tuzuru Facade
- Always use `@Sources/TuzuruLib/Tuzuru.swift` facade to implement commands
- Don't expose internal components directly to commands

### Terminology
- Use "blog" not "site" (e.g., "static blog generator" not "static site generator")

### Amend Command
- Creates marker commits with format: `[tuzuru amend] Updated {field} for {filename}`
- These commits are processed by GitLogReader to override post metadata

## GitHub Actions

### Composite Actions
- `tuzuru-deploy` (`.github/actions/tuzuru-deploy/action.yml`): Complete blog generation and deployment to GitHub Pages
- `tuzuru-generate` (`.github/actions/tuzuru-generate/action.yml`): Blog generation only (no deployment)
- Both actions use the published npm package (`@ainame/tuzuru@0.1.2`) rather than building from source

## Release Workflow

The project uses an automated PR-based release workflow with release-please:

1. **Open release PR**: Run `scripts/release.sh` (optionally with `--dry-run`)
2. **Merge release PR**: Once CI succeeds, the PR auto-merges and the workflow tags the merge commit
3. **Publish assets**: Cross-compiles binaries, uploads to GitHub release, publishes npm package, and updates Homebrew formula

**Important**: Tags remain plain semver (no `v` prefix) and are created by release-please.

## Code Review Focus Areas

When reviewing code, pay special attention to:

1. **Cross-platform compatibility**: Ensure code works on macOS, Linux, and Windows
2. **Path handling**: Verify use of `FilePath` APIs instead of hard-coded separators
3. **File operations**: Check that `FileManagerWrapper` is used instead of `FileManager.default`
4. **Configuration defaults**: Ensure defaults are in `BlogConfiguration+DefaultValues.swift`, not inline
5. **Testing**: Verify tests use swift-testing framework and handle parallel execution correctly
6. **Async/await**: Check proper use of async/await and MainActor isolation
7. **Terminology**: Ensure "blog" is used consistently instead of "site"
8. **Facade pattern**: Verify commands interact through the Tuzuru facade
