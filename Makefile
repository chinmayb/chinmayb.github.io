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

post:
	@read -p "Post title: " title; \
	slug=$$(echo "$$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-'); \
	file="_posts/$$(date +%Y-%m-%d)-$$slug.md"; \
	printf -- "---\nlayout: post\ntitle: \"$$title\"\ndate: $$(date +%Y-%m-%d)\ntags: []\n---\n\n" > $$file; \
	$(EDITOR) $$file; \
	echo "Created $$file"

.PHONY: serve reads books podcasts repos post
