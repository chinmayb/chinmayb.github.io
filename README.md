# chinmayb.github.io

Personal site — Bits & Peace. Built with Jekyll, hosted on GitHub Pages.

## Local development

Requires Ruby 3.3.0 via chruby:

```bash
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
chruby ruby-3.3.0
bundle install
```

```bash
make serve        # start dev server at http://localhost:4000
```

## Editing content

All content lives in plain markdown files with YAML front matter.

```bash
make reads        # _longreads/longreads.md   — long articles
make books        # _longreads/books.md       — books (status: reading/read/want)
make podcasts     # _podcasts/podcasts.md     — podcasts
make repos        # _repos/repos.md           — repos
make post         # create a new dated post interactively
```

### Adding a book

Edit `_longreads/books.md`:

```yaml
books:
  - title: Book Title
    author: Author Name
    status: reading   # reading | read | want
    url: https://...
```

### Adding a long article

Edit `_longreads/longreads.md`:

```yaml
articles:
  - title: Article Title
    url: https://...
```

### Adding a podcast

Edit `_podcasts/podcasts.md`:

```yaml
podcasts:
  - name: Podcast Name
    source: spotify
    url: https://...
```

### Adding a repo

Edit `_repos/repos.md`:

```yaml
repos:
  - name: repo-name
    desc: Short description
    lang: Go
    url: https://github.com/chinmayb/repo-name
```

## Writing a post

```bash
make post
```

Or manually create `_posts/YYYY-MM-DD-title.md`:

```yaml
---
layout: post
title: "Post Title"
date: 2025-01-01
tags: [tag1, tag2]
---

Post content here.
```

## Stack

- Jekyll 4.3 — static site generator
- GitHub Pages — hosting
- Claude warm dark theme — custom CSS, no frameworks
