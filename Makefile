new:
	read str; \
	touch "_posts/$$(date '+%Y-%m-%d')-$$(echo $$str).html"; \
	echo "_posts/$$(date '+%Y-%m-%d')-$$(echo $$str).html"
