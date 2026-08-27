SHELL := /bin/sh

.PHONY: help clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make clean              Remove local, regenerable housekeeping files' \
		'  make clean DRY_RUN=1    Print what clean would remove'

clean:
	@set -eu; \
	paths='.cache tmp logs'; \
	if [ "$(DRY_RUN)" = '1' ]; then \
		for path in $$paths; do [ ! -e "$$path" ] || printf 'would remove %s\n' "$$path"; done; \
		find . -path './.git' -prune -o -type f -name '.DS_Store' -print \
			| sed 's|^|would remove |'; \
	else \
		for path in $$paths; do \
			[ -z "$$(git ls-files -- "$$path")" ] || { printf 'refusing to remove tracked path: %s\n' "$$path" >&2; exit 1; }; \
		done; \
		rm -rf $$paths; \
		find . -path './.git' -prune -o -type f -name '.DS_Store' -exec rm -f {} +; \
	fi
