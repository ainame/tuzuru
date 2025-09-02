# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tuzuru is a static blog generator CLI tool written in Swift that converts markdown files to HTML pages using Mustache templates. It's designed for Swift 6.1 with macOS v15+ minimum requirement.

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
- `swift run tuzuru --help` - Show help

## Architecture

### Package Structure
- **Command target**: CLI interface using ArgumentParser with MainActor isolation
- **TuzuruLib target**: Core library containing business logic
- **Resources**: Template files (Mustache) and static assets

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
`FileManagerWrapper` is a thin wrapper that prevernts us from using unsafe APIs in concurrent context.
It also offers FilePath as currency type instead of URL or String path.

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

## Memory

- Always use @Sources/TuzuruLib/Tuzuru.swift facade to implement a command
- Don't use the term "site" instead use "blog"; ie static site generator -> static blog generator
- The amend command creates marker commits with format `[tuzuru amend] Updated {field} for {filename}` that are processed by GitLogReader to override post metadata
