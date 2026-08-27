SHELL := /bin/sh
ifneq ($(origin MAKEFILE_LIST),file)
$(error refusing overridden MAKEFILE_LIST)
endif
override ROOT := $(realpath $(dir $(realpath $(lastword $(MAKEFILE_LIST)))))

.PHONY: help clean clean-dry-run test-clean

help:
	@printf '%s\n' \
		'Usage:' \
		'  make clean              Remove local, regenerable housekeeping files' \
		'  make clean-dry-run      Print what clean would remove' \
		'  make test-clean         Test cleanup containment and tracked guards'

clean:
	@cd "$(ROOT)"; set -eu; \
	paths='.cache tmp logs'; \
	case "$(DRY_RUN)" in ''|0|1) ;; *) printf 'invalid DRY_RUN value: %s\n' "$(DRY_RUN)" >&2; exit 2;; esac; \
	for path in $$paths; do \
		repo_path=$${path#./}; \
		tracked=$$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git ls-files -- ":(top,icase,literal)$$repo_path") || { printf 'git ls-files failed for %s\n' "$$path" >&2; exit 1; }; \
		[ -z "$$tracked" ] || { printf 'refusing to remove tracked path: %s\n' "$$path" >&2; exit 1; }; \
	done; \
	find . -path './.git' -prune -o -type f -name '.DS_Store' \
		-exec sh -c 'for path do repo_path=$${path#./}; tracked=$$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git ls-files -- ":(top,icase,literal)$$repo_path") || { printf "git ls-files failed for %s\n" "$$path" >&2; exit 1; }; [ -z "$$tracked" ] || { printf "refusing to remove tracked path: %s\n" "$$path" >&2; exit 1; }; done' sh {} +; \
	if [ "$(DRY_RUN)" = '1' ]; then \
		for path in $$paths; do [ ! -e "$$path" ] || printf 'would remove %s\n' "$$path"; done; \
		find . -path './.git' -prune -o -type f -name '.DS_Store' \
			-exec sh -c 'for path do printf "would remove %s\n" "$$path"; done' sh {} +; \
	else \
		rm -rf $$paths; \
		find . -path './.git' -prune -o -type f -name '.DS_Store' -exec rm -f -- {} +; \
	fi

clean-dry-run:
	@$(MAKE) -C "$(ROOT)" clean DRY_RUN=1

test-clean:
	@"$(ROOT)/scripts/clean.test.sh"
