# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tuzuru is a Swift-based static site generator that converts markdown files to HTML websites. It follows SOLID principles with a clean, modular architecture focused on Single Responsibility Principle.

## Essential Commands

### Build and Run
```bash
# Build the project
swift build

# Run the site generator (from project root)
swift run tuzuru generate

# Build for release
swift build -c release

# Run with release build
swift run -c release tuzuru generate
```

### Development Commands
```bash
# Test the system with sample blog in tmp/
cd tmp/
swift run -c release --package-path ../ tuzuru generate

# Clean build artifacts
swift package clean

# Resolve package dependencies
swift package resolve
```

## Architecture Overview

The codebase uses a **compositional architecture** where the main `Tuzuru` class orchestrates focused, single-responsibility components:

```
Tuzuru (Orchestrator)
├── ContentLoader    # Loads markdown files and git metadata
├── SiteGenerator    # Renders templates and generates HTML
└── MarkdownProcessor # Converts markdown to HTML
```

### Core Data Flow
1. **ContentLoader** scans directories for markdown files, extracts git history (author, dates), and creates `Page` objects
2. **MarkdownProcessor** handles markdown-to-HTML conversion, title extraction, and excerpt generation
3. **SiteGenerator** loads Mustache templates and renders final HTML files using **SiteConfiguration**

### Key Components

- **SiteConfiguration**: Eliminates all hardcoded assumptions (file paths, directory names, metadata)
- **TemplateConfiguration**: Configurable template file paths
- **OutputConfiguration**: Configurable output directories and file extensions
- **SiteMetadata**: Configurable site titles and metadata

### Configuration System

The system is **fully configurable** with zero hardcoded assumptions:

```swift
// Default usage
let tuzuru = Tuzuru()

// Custom configuration
let config = SiteConfiguration(
    output: OutputConfiguration(directory: "public"),
    metadata: SiteMetadata(blogTitle: "My Tech Blog")
)
let tuzuru = Tuzuru(configuration: config)
```

## Template System

Uses **three-tier templating**:
1. **Layout template** (`layout.mustache`) - Overall page structure with `{{{content}}}` injection
2. **Article template** (`article.html`) - Individual post layout
3. **List template** (`list.html`) - Index page with article listings

Templates use Mustache syntax with variables like `{{title}}`, `{{author}}`, `{{publishedAt}}`.

## Git Integration

The system **automatically extracts metadata** from git history:
- First commit date becomes publication date
- First commit author becomes article author
- Uses `GitWrapper` with `swift-subprocess` for git operations

## Dependencies

- **swift-argument-parser**: CLI interface
- **swift-mustache**: Template rendering (Hummingbird project version)
- **swift-markdown**: Markdown parsing and HTML conversion
- **swift-subprocess**: Git operations
- **System**: File path operations (from macOS SDK)

## Project Structure

```
Sources/
├── Command/           # CLI entry point and commands
└── TuzuruLib/         # Core library components
    ├── Tuzuru.swift          # Main orchestrator (21 lines)
    ├── ContentLoader.swift   # Markdown file processing
    ├── SiteGenerator.swift   # HTML generation
    ├── MarkdownProcessor.swift # Markdown-to-HTML conversion
    ├── SiteConfiguration.swift # Configuration system
    └── ConfigurationExamples.swift # Usage examples
```

## Testing Environment

The `tmp/` directory contains a **complete working blog** with 8 sample articles across different categories (tech, travel, recipes, life). Use this for testing changes:

```bash
cd tmp/
rm -rf site/  # Clean previous output
swift run -c release --package-path ../ tuzuru generate
```

## Key Design Decisions

1. **Single Responsibility Principle**: Each class has one focused job
2. **Configuration over Convention**: Everything is configurable via `SiteConfiguration`
3. **Git-based metadata**: Publication dates and authors from git history
4. **Mustache templating**: Simple, logic-less templates
5. **Swift 6.2 with System framework**: Modern Swift with native file operations

## Refactoring History

The codebase was refactored from a monolithic 346-line `Tuzuru` class into focused components. The main class is now just 21 lines and delegates to specialized components, following SOLID principles while maintaining full backward compatibility.