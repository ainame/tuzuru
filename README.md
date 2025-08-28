# Tuzuru

A dead simple blogging tool in Swift.

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
    "locale": "en_US" // this will affect published date format
  },
  "outputOptions": {
    "directory": "blog",
    "style": "subdirectory"  // or "direct" for .html files
  },
  "sourceLayout": {
    "assets": "assets",
    "contents": "contents",
    "templates": {
      "postFile" : "templates/post.html.mustache",
      "layoutFile" : "templates/layout.html.mustache",
      "listFile" : "templates/list.html.mustache"
    }
  }
}
```

## Writing Content

1. Add `.md` files to `contents/`
2. Files can be in subdirectories for organization
3. Use standard markdown syntax

## Author & Publication Date

Tuzuru automatically extracts metadata from git:

- **Author**: First commit author of the markdown file
- **Published Date**: Date of first commit for the markdown file

Make sure your files are committed to git for proper metadata extraction.

## Output

Generated files appear in the configured output directory (`blog/` by default):

- `index.html` - List of all posts
- `post-name/index.html` - Individual post pages (subdirectory style)
- OR `post-name.html` - Individual post pages (direct style)
