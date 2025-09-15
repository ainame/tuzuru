# AGENTS.md

This file provides guidance to AI coding agents (e.g., Claude Code, GitHub Copilot, OpenAI Codex CLI) when working with code in this repository.

## Project Overview

Tuzuru is a static blog generator CLI tool written in Swift that converts markdown files to HTML pages using Mustache templates. It's designed for Swift 6.1 with macOS v15+ minimum requirement.
Note: The codebase also includes conditional support for Linux (Glibc/Musl) in the local HTTP server component.

## Essential Commands

### Development
- `swift build` - Build the project
- `swift run tuzuru` - Run the CLI tool
- `swift test` - Run all tests
- `swift test --parallel` - Run tests in parallel

### Tuzuru CLI Commands
- `swift run tuzuru generate` - Generate static blog (default command)
- `swift run tuzuru init` - Init a blog project
- `swift run tuzuru import` - Import posts from other project using Hugo or Jekyll
- `swift run tuzuru amend` - Update publishedAt date and/or author for a markdown file by creating marker commits
- `swift run tuzuru list` - List blog posts with metadata in CSV format
- `swift run tuzuru serve` - Start a local HTTP server to serve the generated blog with auto-regeneration
- `swift run tuzuru --help` - Show help

#### Serve Command Options
- `-p, --port <port>` - Port to serve on (default: 8000)
- `-c, --config <config>` - Path to configuration file (default: tuzuru.json)

The output directory is determined by `output.directory` in `tuzuru.json` (default: `blog`). There is no `--directory` option in the current implementation.

The serve command includes auto-regeneration capability that automatically rebuilds the blog when source files are modified, providing a live development experience.
It uses the internal `ToyHttpServer` target and is intended only for local development, not production use.

#### Generate Command Options
- `-c, --config <config>` - Path to configuration file (default: tuzuru.json)

#### Init Command Options
- (none)

#### Import Command Options
- `<sourcePath>` (argument) - Source directory containing markdown files to import
- `-d, --destination <path>` - Destination directory (default: `contents/imported/` or `sourceLayout.imported`)
- `-u, --unlisted` - Import as unlisted content (uses `sourceLayout.unlisted`)
- `-n, --dry-run` - Show actions without making changes
- `-c, --config <config>` - Path to configuration file (default: tuzuru.json)

#### Amend Command Options
- `<filePath>` (argument) - Path to markdown file (relative to `contents`)
- `-d, --published-at <date>` - New published date (flexible formats supported)
- `-a, --author <name>` - New author name
- `-c, --config <config>` - Path to configuration file (default: tuzuru.json)

At least one of `--published-at` or `--author` must be provided.

#### List Command Options
- `-c, --config <config>` - Path to configuration file (default: tuzuru.json)

The list command outputs blog posts in CSV format with columns: "Published At", "Author", "Title", "File Path".
Titles are truncated to 40 characters with "..." if longer. Supports all international scripts and Unicode characters.
Output format: `"Published At", "Author", "Title", "File Path"` with single space after each comma for readability.

## Architecture

### Package Structure
- **Command target**: CLI interface using ArgumentParser with MainActor isolation
- **TuzuruLib target**: Core library containing business logic
   - **Resources**: Template files (Mustache) and static assets
- **ToyHttpServer target**: Minimal HTTP server for local development (used by `serve`)

### Key Dependencies
- swift-argument-parser: CLI parsing
- swift-mustache: Template rendering
- swift-markdown: Markdown processing
- swift-system: File system operations
- swift-subprocess: Process execution
- Yams: YAML parsing

### Core Components
- `Sources/Command/Command.swift`: CLI command definitions using ArgumentParser
- `Sources/TuzuruLib/Tuzuru.swift`: Main facade that commands will interact with
- `Sources/TuzuruLib/Configuration/`: Configuration management
- `Sources/TuzuruLib/Generator/`: HTML generation logic
- `Sources/TuzuruLib/SourceLoader/`: Content loading and parsing
- `Sources/TuzuruLib/Importer/`: Content import functionality
- `Sources/TuzuruLib/Amender/`: File metadata amending functionality
- `Sources/TuzuruLib/Initializer/`: Blog bootstrap and resource copy logic
- `Sources/TuzuruLib/Utils/`: Utilities including `FileManagerWrapper`, `GitWrapper`, `ChangeDetector`
- `Sources/ToyHttpServer/`: Local HTTP server implementation

### File Conventions
- Source markdown files: `contents/` directory
- Generated output: `blog/` directory
- Templates: Mustache format (.mustache extension)

## Swift Conventions

### Code Style
- Swift 6.1 features enabled
- MainActor isolation for Command target
- Public interfaces for library components
- Dependency injection pattern (e.g., FileManager injection)
- Async/await for command execution
- **IMPORTANT**: Default values for configuration structs must be defined in `BlogConfiguration+DefaultValues.swift`, NEVER inline in the decoder methods

### Naming
- Structs: PascalCase (MainCommand, GenerateCommand)
- Properties/Methods: camelCase with descriptive names
- Use descriptive method names like `loadSources(_:)`, `generate(_:)`

### File operations

To support swift-testing or modern APIs using async/await; ie `Subprocess`, this project got `FileManagerWrapper`.
`FileManagerWrapper` is a thin wrapper that prevents us from using unsafe APIs in concurrent context.
It also offers `FilePath` as the primary type instead of URL or String path.

Please try to inject `FileManagerWrapper` from the upstream code when possible.
Never use `FileManager.default` directly.

Especially, when you need to work with Subprocess or GitWrapper,
you must give `FileManagerWrapper.workingDirectory` to ensure you run command at right place.
This is for testing purpose due to swift-testing's parallel execution.
`GitRepositoryFixtureTrait` works on top of that way.

## Testing

### Unit testing

- Use swift-testing (Testing) framework
- Create very minimum test cases that is only happy-path + important edge cases

### E2E testing (blog generation)

- Use `./tmp` directory with git (tuzuru command depends on a git project)
- Don't delete `./tmp`

## GitHub Actions

The project provides two composite GitHub Actions for use in workflows:

### `tuzuru-deploy` Action (`.github/actions/tuzuru-deploy/action.yml`)
- **Purpose**: Complete blog generation and deployment to GitHub Pages
- **Description**: "Install tuzuru via npm, generate blog, and deploy to GitHub Pages"
- **Steps**:
  1. Setup Node.js (v22)
  2. Install Tuzuru globally (`@ainame/tuzuru@0.1.2`)
  3. Generate blog using `tuzuru generate`
  4. Extract output directory from config (defaults to `blog`)
  5. Upload Pages artifact
  6. Deploy to GitHub Pages
- **Inputs**:
  - `config`: Path to tuzuru.json (optional, relative to working-directory)

### `tuzuru-generate` Action (`.github/actions/tuzuru-generate/action.yml`)
- **Purpose**: Blog generation only (no deployment)
- **Description**: "Install tuzuru via npm and run 'tuzuru generate'"
- **Steps**:
  1. Setup Node.js (v22)
  2. Install Tuzuru globally (`@ainame/tuzuru@0.1.2`)
  3. Generate blog using `tuzuru generate`
- **Inputs**:
  - `config`: Path to tuzuru.json (optional, relative to working-directory)

Both actions use the published npm package `@ainame/tuzuru@0.1.2` rather than building from source.

## Release Workflow

The project uses an automated PR-based release workflow:

### Release Process
1. **Create Release PR**: Run `scripts/release.sh <version>` (e.g., `scripts/release.sh 1.2.3`)
   - Updates version in Swift source files and package.json
   - Updates GitHub Action composite actions to use new npm version
   - Runs build and tests locally
   - Creates release branch and PR with `[Version Bump]` title prefix

2. **Automated Release**: When the PR is merged to main:
   - `.github/workflows/release.yml` triggers on commit messages containing `[Version Bump]`
   - `scripts/auto-tag.sh` creates git tag from current version
   - Workflow builds cross-platform binaries (macOS universal, Linux x86_64/aarch64)
   - Updates Homebrew Formula with correct SHA256
   - Creates GitHub release with all assets
   - Publishes to npm registry

### Key Scripts
- `scripts/release.sh`: Creates version bump PR with proper title format
- `scripts/auto-tag.sh`: Extracts version and creates git tag (used by workflow)

### Important Notes
- Release workflow depends on `[Version Bump]` commit message prefix
- Tags are created without 'v' prefix (e.g., `1.2.3`, not `v1.2.3`)
- Homebrew Formula is updated during release workflow, not during PR creation

## Memory

- Always use @Sources/TuzuruLib/Tuzuru.swift facade to implement a command
- Don't use the term "site" instead use "blog"; ie static site generator -> static blog generator
- The amend command creates marker commits with format `[tuzuru amend] Updated {field} for {filename}` that are processed by GitLogReader to override post metadata
