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
├── SourceLoader     # Loads markdown files and git metadata from contents/ and contents/unlisted/
├── BlogGenerator    # Renders templates and generates HTML
└── PathGenerator    # Generates clean URLs and file paths
```

### Core Data Flow
1. **SourceLoader** scans both `contents/` and `contents/unlisted/` directories for markdown files, extracts git history (author, dates), and creates `Post` objects with `isUnlisted` flag
2. **MarkdownProcessor** handles markdown-to-HTML conversion, title extraction, and excerpt generation
3. **BlogGenerator** loads Mustache templates, filters unlisted posts from indexes, and renders final HTML files
4. **PathGenerator** creates clean URLs, routing unlisted posts without the `unlisted/` path prefix

### Key Components

- **BlogConfiguration**: Eliminates all hardcoded assumptions (file paths, directory names, metadata)
- **SourceLayout**: Configurable source file paths including `contents`, `unlisted`, `assets`, and `templates`
- **OutputOptions**: Configurable output directories and file extensions
- **BlogMetadata**: Configurable site titles and metadata
- **Post**: Contains content and metadata, with `isUnlisted` flag for unlisted content

### Configuration System

The system is **fully configurable** with zero hardcoded assumptions:

```swift
// Default usage (requires configuration parameter)
let config = BlogConfiguration(/* ... */)
let tuzuru = try Tuzuru(configuration: config)

// Custom configuration
let config = BlogConfiguration(
    sourceLayout: SourceLayout(
        templates: Templates(/* ... */),
        contents: FilePath("contents"),
        unlisted: FilePath("contents/unlisted"),  // New: unlisted content support
        assets: FilePath("assets")
    ),
    output: OutputOptions(directory: "public"),
    metadata: BlogMetadata(blogName: "My Tech Blog")
)
let tuzuru = try Tuzuru(configuration: config)
```

## Template System

Uses **three-tier templating**:
1. **Layout template** (`layout.mustache`) - Overall page structure with `{{{content}}}` injection
2. **Post template** (`post.mustache`) - Individual post layout
3. **List template** (`list.mustache`) - Index page with post listings

Templates use Mustache syntax with variables like `{{title}}`, `{{author}}`, `{{publishedAt}}`.

### Unlisted Content Support

- **Unlisted posts** are processed and get individual pages but are excluded from list pages and yearly indexes
- Default location: `contents/unlisted/` (configurable via `SourceLayout.unlisted`)
- **Clean URL routing**: unlisted posts route directly (e.g., `/about/`) without `unlisted/` path prefix
- Perfect for static pages like About, Contact, Privacy Policy that need direct links but shouldn't appear in navigation
- Can be linked from templates: `<a href="/about/">About</a>` in `layout.mustache`

## Git Integration

The system **automatically extracts metadata** from git history:
- First commit date becomes publication date
- First commit author becomes post author
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
│   ├── Command.swift         # Main CLI command structure
│   ├── InitCommand.swift     # 'tuzuru init' - creates new sites with unlisted support
│   └── GenerateCommand.swift # 'tuzuru generate' - builds the site
└── TuzuruLib/         # Core library components
    ├── Tsuzuru.swift         # Main orchestrator (32 lines)
    ├── BlogGenerator.swift   # HTML generation with unlisted filtering
    ├── PathGenerator.swift   # URL and file path generation
    ├── BlogInitializer.swift # Template and asset file copying
    ├── TuzuruError.swift     # Error types
    ├── Models/               # Data structures
    │   ├── BlogConfiguration.swift # Main configuration
    │   ├── SourceLayout.swift     # Source file paths (includes unlisted)
    │   ├── Post.swift             # Post model with isUnlisted flag
    │   ├── Source.swift           # Collection of posts and metadata
    │   └── [other models]
    ├── SourceLoader/         # Markdown processing
    │   ├── SourceLoader.swift     # Scans contents/ and contents/unlisted/
    │   ├── MarkdownDestructor.swift # Title extraction
    │   ├── MarkdownExcerptWalker.swift # Excerpt generation
    │   └── [other processors]
    ├── Renderer/             # Template rendering
    └── Resources/            # Bundled templates and assets
```

## Testing Environment

The `tmp/` directory contains a **complete working blog** with 9 sample posts across different categories (tech, travel, recipes, life) plus unlisted content. Use this for testing changes:

```bash
cd tmp/
rm -rf blog/  # Clean previous output
swift run -c release --package-path ../ tuzuru generate
```

### Testing Unlisted Content

The test environment includes:
- Sample unlisted page: `tmp/contents/unlisted/about.md`
- Updated `tmp/tuzuru.json` with unlisted configuration
- Unlisted content generates at clean URLs (e.g., `/about/`) and is excluded from indexes

## Key Design Decisions

1. **Single Responsibility Principle**: Each class has one focused job
2. **Configuration over Convention**: Everything is configurable via `BlogConfiguration`
3. **Git-based metadata**: Publication dates and authors from git history
4. **Mustache templating**: Simple, logic-less templates
5. **Swift 6.2 with System framework**: Modern Swift with native file operations
6. **Unlisted content support**: Clean URL routing for static pages without appearing in navigation
7. **Dual directory scanning**: Separate handling of regular and unlisted content with filtering

## Recent Updates

### Unlisted Content Feature (Latest)
- Added `SourceLayout.unlisted` property with default `"contents/unlisted"`
- Enhanced `Post` model with `isUnlisted` boolean flag
- Updated `SourceLoader` to scan both `contents/` and `contents/unlisted/` separately
- Modified `BlogGenerator` to filter unlisted posts from index and yearly pages
- Enhanced `PathGenerator` with clean URL routing (no `unlisted/` prefix in URLs)
- Updated `InitCommand` to create unlisted directory and include in default configuration

## Refactoring History

The codebase was refactored from a monolithic 346-line `Tuzuru` class into focused components. The main class is now just 32 lines and delegates to specialized components, following SOLID principles while maintaining full backward compatibility.