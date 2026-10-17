# chinmayb.github.io

Jekyll site (GitHub Pages, deployed by `.github/workflows/pages.yml`).

## Verify changes locally

System Ruby is too old for Jekyll 4, so build in Docker before committing:

    make verify

It runs `jekyll build` in a `ruby:3.2` container and checks that the photos
section rendered into `_site/index.html`. Run it after any change to
`index.html`, `_layouts/`, `_includes/`, `_data/`, `assets/` or the Gemfile.

To view the site, run `make docker-serve` and open <http://localhost:4000>
(`make serve` needs a local Ruby 3+, which this machine lacks).

## Markdown lint

Run `make lint-md` after adding or editing any `.md` file (posts in `_posts/`,
`CLAUDE.md`, `README.md`) and fix everything it reports before committing. It runs
markdownlint in Docker with the rules in `.markdownlint-cli2.jsonc` (line length
and inline HTML are allowed). Fenced code blocks need a language and images need
alt text.

## Tabs and URLs

The home page lives in `_includes/home.html`. `index.html`, `reading/`, `listening/`,
`repos/` and `photos/` each include it with a `tab=` value, so every tab has a real
URL (e.g. chinmaya.fyi/photos/). Clicking a tab switches instantly and updates the
URL with `history.pushState`. A new tab needs a section, a button and a folder.

## Photos tab

- `scripts/fetch_instagram.py` writes `_data/photos.json` (gitignored) from the
  Instagram API using `IG_ACCESS_TOKEN`. Locally it is not run; the file stays `[]`.
- When that list is empty the page falls back to `_data/photos_sample.json`.
- Music (`assets/audio/`) starts on the Photos tab click via `window.photoMusic` in `index.html`.
- Icon toggle above the photos switches Grid / Slider. Slider is vertical (wheel, arrows, swipe, buttons) over a blurred backdrop and reuses the grid's figures.
