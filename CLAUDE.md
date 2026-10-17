# chinmayb.github.io

Jekyll site (GitHub Pages, deployed by `.github/workflows/pages.yml`).

## Verify changes locally

System Ruby is too old for Jekyll 4, so build in Docker before committing:

    make verify

It runs `jekyll build` in a `ruby:3.2` container and checks that the photos
section rendered into `_site/index.html`. Run it after any change to
`index.html`, `_layouts/`, `_includes/`, `_data/`, `assets/` or the Gemfile.

To view the site, run `make docker-serve` and open http://localhost:4000
(`make serve` needs a local Ruby 3+, which this machine lacks).

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
