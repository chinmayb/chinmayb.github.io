EDITOR ?= $(shell echo $${VISUAL:-$${EDITOR:-open}})

serve:
	bundle exec jekyll serve --port 4000

reads:
	$(EDITOR) _longreads/longreads.md

books:
	$(EDITOR) _longreads/books.md

podcasts:
	$(EDITOR) _podcasts/podcasts.md

repos:
	$(EDITOR) _repos/repos.md

# Build and serve in Docker at http://localhost:4000 (live reload on file changes).
docker-serve:
	docker run --rm --init $(shell [ -t 0 ] && echo -it) -p 4000:4000 -p 35729:35729 -v "$$PWD":/srv -w /srv ruby:3.2 sh -c \
	  "bundle config set path /tmp/bundle >/dev/null && bundle install >/dev/null && bundle exec jekyll serve --host 0.0.0.0 --port 4000 --livereload"

# Build the site in Docker (system Ruby is too old for Jekyll 4). Output goes to _site.
verify:
	docker run --rm -v "$$PWD":/srv -w /srv ruby:3.2 sh -c \
	  "bundle config set path /tmp/bundle >/dev/null && bundle install >/dev/null && bundle exec jekyll build -d /tmp/out && rm -rf /srv/_site && cp -r /tmp/out /srv/_site"
	@grep -q 'class="photo"' _site/index.html && echo "ok: photos section rendered" || (echo "FAIL: no photos rendered"; exit 1)

# Lint markdown (CLAUDE.md, README.md, _posts/*.md) with markdownlint in Docker. Config: .markdownlint-cli2.jsonc.
lint-md:
	docker run --rm -v "$$PWD":/workdir davidanson/markdownlint-cli2:latest

post:
	@read -p "Post title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'); \
	file="_posts/$$(date +%Y-%m-%d)-$$slug.md"; \
	printf -- "---\nlayout: post\ntitle: \"$$title\"\ndate: $$(date +%Y-%m-%d)\ntags: []\n---\n\n" > $$file; \
	$(EDITOR) $$file; \
	echo "Created $$file"

.PHONY: serve docker-serve verify lint-md reads books podcasts repos post
