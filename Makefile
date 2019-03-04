go:
	(sleep 5; open 'http://127.0.0.1:4000') &
	bundle exec jekyll serve

new:
	read str; \
	touch "_posts/$$(date '+%Y-%m-%d')-$$(echo $$str).html"; \
	echo "_posts/$$(date '+%Y-%m-%d')-$$(echo $$str).html"
