.DEFAULT_GOAL:= help

.PHONY: check shellcheck shfmt help

check: shfmt shellcheck ## Static analysis files existing in repository.

shellcheck: ## Check shell scripts.
	@if ! command -v 'shellcheck' &> /dev/null; then \
  		echo "Please install shellcheck! See https://www.shellcheck.net"; exit 1; \
  	fi;
	@shellcheck *.sh

shfmt: ## Format shell scripts.
	@if ! command -v 'shfmt' &> /dev/null; then \
  		echo 'Please install shfmt! See https://github.com/mvdan/sh'; exit 1; \
  	fi;
	@shfmt -d -s -w -i 4 -ln bash *.sh

help: ## Print this help.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
