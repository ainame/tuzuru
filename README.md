# Tuzuru

A dead simple static site generator in Swift with support for unlisted content.

## Quick Start

```bash
# Initialize a new site
tuzuru init

# Generate your site
tuzuru generate
```

## Commands

- `tuzuru init` - Create a new site with default structure and configuration
- `tuzuru generate` - Build your site from markdown files

## Project Structure

After running `tuzuru init`, you'll have:

```
├── tuzuru.json      # Site configuration
├── contents/        # Your markdown files go here
│   └── unlisted/    # Unlisted content (about, contact, etc.)
├── templates/       # Mustache templates for layout
├── assets/          # Static files (images, CSS, etc.)
└── blog/            # Generated site output
```

## Configuration (tuzuru.json)

Edit `tuzuru.json` to customize your site:

```json
{
  "metadata": {
    "blogName": "My Blog",
    "copyright": "2025 My Blog",
    "locale": "en_GB"
  },
  "outputOptions": {
    "directory": "blog",
    "style": "subdirectory"  // or "direct" for .html files
  },
  "sourceLayout": {
    "assets": "assets",
    "contents": "contents",
    "unlisted": "contents/unlisted",  // New: unlisted content directory
    "templates": {
      "postFile": "templates/post.mustache",
      "layoutFile": "templates/layout.mustache",
      "listFile": "templates/list.mustache"
    }
  }
}
```

## Writing Content

### Regular Posts

1. Add `.md` files to `contents/`
2. Files can be in subdirectories for organization
3. Use standard markdown syntax
4. Posts appear in the main index and yearly archives

### Unlisted Content

1. Add `.md` files to `contents/unlisted/`
2. Perfect for static pages like About, Contact, Privacy Policy
3. Pages get individual URLs but don't appear in post lists or archives
4. Link to them from templates: `<a href="/about/">About</a>` in `layout.mustache`

#### Example unlisted content:

```markdown
# About This Blog

Welcome to my personal blog! This page won't appear in the main post list.

## About Me

I'm a developer who loves exploring new technologies...
```

**URL routing**: `contents/unlisted/about.md` → `/about/` (clean URLs without `unlisted/` prefix)

## Author & Publication Date

Tuzuru automatically extracts metadata from git:

- **Author**: First commit author of the markdown file
- **Published Date**: Date of first commit for the markdown file

Make sure your files are committed to git for proper metadata extraction.

## Output

Generated files appear in the configured output directory (`blog/` by default):

- `index.html` - List of all posts (excluding unlisted content)
- `YYYY/index.html` - Yearly archives (excluding unlisted content)
- `post-name/index.html` - Individual post pages (subdirectory style)
- `about/index.html` - Unlisted pages with clean URLs
- OR `post-name.html`, `about.html` - Individual pages (direct style)

## Features

- **Git-based metadata**: Automatically extracts authors and publication dates from git history
- **Configurable output styles**: Choose between subdirectory or direct HTML files
- **Mustache templating**: Simple, logic-less templates
- **Yearly archives**: Automatic generation of year-based post indexes
- **Unlisted content support**: Create static pages that don't appear in navigation
