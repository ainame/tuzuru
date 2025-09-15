# Tuzuru

[![Swift Version](https://img.shields.io/badge/Swift-6.1+-blue.svg)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/ainame/tuzuru/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/ainame/tuzuru)](https://github.com/ainame/tuzuru/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/ainame/tuzuru/ci.yml?branch=main)](https://github.com/ainame/tuzuru/actions)

Tuzuru (綴る) is a dead-simple static **blog** generator CLI that uses Git to manage your blog metadata.
Just write and commit plain Markdown files—no front matter needed.
Tuzuru automatically derives metadata such as dates and author from your Git history.

![logo](.github/assets/logo.png)

It is designed to keep workflows minimal, allowing you to focus on writing.

* Simple plain Markdown format, no YAML required
  * Instead of YAML front matter, Tuzuru pulls the publication date and author from Git.
* Simple routing with auto-generated listing pages
  * Yearly archives and category-based listings are created automatically.
* Simple preview server with built-in watch mode
  * `tuzuru serve` automatically rebuilds on requests.
* Simple installation with minimal setup
  * Install via Homebrew, npm, or download a binary from GitHub Releases.
* Simple deployment with built-in GitHub Actions
  * From installation to deployment, everything is handled for you.

## Installation

### npm (Cross-platform)

```bash
npm install -g @ainame/tuzuru
```

This will download and install the appropriate prebuilt binary for your platform (macOS or Linux).

### Homebrew (macOS)

```bash
brew tap ainame/tuzuru https://github.com/ainame/Tuzuru
brew install tuzuru
```

### Manual Build

```bash
swift build -c release
cp .build/release/tuzuru /path/to/bin
```

## Getting started

You first need to set up a Git repo locally.

```bash
mkdir new-blog
cd new-blog
git init

# Initialize a blog project
# This adds `assets`, `contents`, `templates` directories and `tuzuru.json`
tuzuru init

git add .
git commit -m "init commit"
```

Then create a markdown file under the `contents` directory and do `git commit`.

``` bash
emacs contents/first-blog-post.md
git add contents/first-blog-post.md
git commit -m "First post"
```

When you make `git commit` becomes your post's published date.
Specifically, the first commit's Author Date for a markdown file under `contents` is the published date and also, author name will be taken from Git's config.

Now it's time to build your blog.

``` bash
tuzuru generate
```

You can now see the `blog` directory that can be deployed to GitHub Pages or your favorite HTTP server.

For local development, use the built-in serve command:

``` bash
tuzuru serve
```

This starts a local HTTP server at `http://localhost:8000` with auto-regeneration enabled. When you modify source files, the blog will be automatically rebuilt on the next request.

### Deployment

This repo has two GitHub Actions prepared for Tuzuru blogs to set up deployment easily.

* [ainame/Tuzuru/.github/actions/tuzuru-deploy](https://github.com/ainame/tuzuru/blob/main/.github/actions/tuzuru-deploy/action.yml)
   * Install tuzuru via npm, generate blog, upload the artefact, and deploy to GitHub page
* [ainame/Tuzuru/.github/actions/tuzuru-generate](https://github.com/ainame/tuzuru/blob/main/.github/actions/tuzuru-generate/action.yml)
   * Only install tuzuru via npm and generate blog
   * You can deploy to anywhere you like

Their versions should match the CLI’s version. When you update the CLI version, you should also update the action’s version.
It is recommended to use Renovate or Dependabot to keep it up to date.

**Note that sicne Tuzuru relies on Git history, you have to checkout git repo with the entire history. Specify `fetch-deploy: 0` in `actions/checkout`**

This is an exmaple `.github/workflows/deploy.yml`.

<details>

```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
      - uses: ainame/Tuzuru/.github/actions/tuzuru-deploy@0.1.2
```

</details>

### Built-in layout

The built-in layout is a great starting point and is easy to customize. It already includes [github-markdown-css](https://github.com/sindresorhus/github-markdown-css) and [highlight.js](https://highlightjs.org/) to make writing tech blog posts a breeze.

![screenshot](.github/assets/screenshot.png)

### Demo

You can see Tuzuru in action with this demo blog hosted on GitHub Pages:

- **Live Demo**: [https://ainame.tokyo/tuzuru-demo/](https://ainame.github.io/tuzuru-demo/)
- **Source Repository**: [https://github.com/ainame/tuzuru-demo](https://github.com/ainame/tuzuru-demo)

This demo showcases the built-in layout.

## How it works

This is how a tuzuru project look like.

```
my-blog/
├── contents/
│   ├── hello-world.md          # → /hello-world
│   ├── tech/
│   │   └── swift-tips.md       # → /tech/swift-tips (listed on /tech)
│   └── unlisted/
│       └── about.md            # → /about (not listed anywhere. You can link to /about from layout.mustache manually)
├── templates/
│   ├── layout.mustache
│   ├── post.mustache
│   └── list.mustache
├── assets/
│   └── main.css
└── tuzuru.json
```

* `contents/` - where you put markdown files
* `templates/` - layout files
* `assets/` - place to locate your assets files, like css or images
* `tuzuru.json` - configuration

### Layout and customization

Tuzuru supports two types of pages.

1. Post - a blog article
2. List - a listing page generated automatically

You can customize these layouts using three Mustache files:

* templates/layout.mustache - Base layout
* templates/post.mustache - main part of post page
* templates/list.mustache - main part of list page

For more on syntax, see the documentation.
https://docs.hummingbird.codes/2.0/documentation/hummingbird/mustachesyntax/

### Listing and Unlisted Pages

By default, any Markdown file in the `contents` directory is automatically listed on:

* The home page (`/`) based on your configuration.
* Yearly archive pages (e.g., `/2025`, `/2024`).
* Category pages for files in subdirectories (e.g., `contents/tech/swift.md` is listed on `/tech`).

You can add an unlisted page by placing it in `contents/unlisted/`. These pages won't be listed anywhere automatically, but you can link to them manually from your templates.

### Assets

The `tuzuru init` command creates an assets directory containing `main.css`. The tuzuru generate command copies all files from this directory to `blog/assets`.

To prevent browser cache issues, use the `{{buildVersion}}` variable in your templates.


```mustache
<link rel="stylesheet" href="{{assetsUrl}}main.css?{{buildVersion}}">
```

### tuzuru.json

`tuzuru.json` is the main configuration file.
By default, you get only `metadata` section by `tuzuru init` but
here's the rest of customization you can do.


```javascript
{
  // `metadata` is the only mandatory section.
  "metadata" : {
    "blogName" : "My Blog",
    "copyright" : "My Blog",
    "description" : "My personal blog", // Meta description for SEO
    "baseUrl" : "https://example.com/",  // Production URL
    "locale" : "en_GB" // Affects the published date format
  },
  // `output` for configuring output options
  "output" : {
    "directory" : "blog", // The output directory
    "homePageStyle" : "all", // "all", "pastYear", or a number (last X posts)
    "routingStyle" : "subdirectory" // "subdirectory" (e.g., /hello-world) or "direct" (e.g., /hello-world.html)
  },
  // `sourceLayout` to customize the default directory structure (typically not needed)
  "sourceLayout" : {
    "assets" : "assets",
    "contents" : "contents",
    "imported" : "contents/imported",
    "templates" : {
      "layout" : "templates/layout.mustache",
      "list" : "templates/list.mustache",
      "post" : "templates/post.mustache"
    },
    "unlisted" : "contents/unlisted"
  }
}
```

## Import posts from Hugo project

You can import Markdown files from a Hugo project. Tuzuru will parse the YAML front matter to get the title, author, and date, then remove it. Each imported Markdown file will be added as an individual Git commit.

```bash
tuzuru import /path/to/import-target-dir # import them to ./contents/imported by default
tuzuru import /path/to/import-target-dir --destination /path/to/import
```

## Amend published date or author

Need to change a post's published date or author without rewriting your Git history? Use the amend command.

```bash
# Update published date
tuzuru amend contents/my-post.md --published-at "2023-12-01"

# Update author
tuzuru amend contents/my-post.md --author "New Author"

# Update both
tuzuru amend contents/my-post.md --published-at "2023-12-01 10:30:00 +0900" --author "New Author"
```

The command supports flexible date formats:

- `2023-12-01` (date only)
- `2023-12-01 10:30:00` (date and time)
- `2023-12-01T10:30:00Z` (ISO 8601 UTC)
- `2023-12-01 10:30:00 +0900` (with timezone)

This command creates a special marker commit that Tuzuru recognizes for post metadata, leaving your history clean.

## Local Development Server

Tuzuru includes a built-in HTTP server for local development:

```bash
# Basic usage (serves on port 8000)
tuzuru serve

# Custom port
tuzuru serve --port 3000

# Custom directory (default is 'blog')
tuzuru serve --directory my-output

# Custom config file
tuzuru serve --config my-config.json
```

### Auto-regeneration

The serve command automatically watches for changes in your source files and regenerates the blog when needed:

- **Content files**: Watches `contents/` and `contents/unlisted/` directories
- **Asset files**: Watches the `assets/` directory
- **Templates**: Watches template files for changes

When files are modified, the blog is regenerated on the next HTTP request, providing a seamless development experience without manual rebuilds.

## Build Requirements

- Swift 6.1+
- macOS v15+

