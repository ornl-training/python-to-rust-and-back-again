#!/usr/bin/env make

SHELL := /bin/sh
.DEFAULT_GOAL := help
# Prefer R on PATH, then fall back to an installed but unlinked Homebrew formula.
R ?= $(shell if command -v R >/dev/null 2>&1; then command -v R; elif command -v brew >/dev/null 2>&1 && brew list --versions r >/dev/null 2>&1; then printf '%s/bin/R' "$$(brew --prefix r)"; else printf 'R'; fi)
R_FLAGS ?= --quiet --no-save --no-restore
R_LIBRARY ?= $(CURDIR)/.r-library
HOST ?= 127.0.0.1
PORT ?= 3435

export R_LIBS_USER := $(R_LIBRARY)

help: ## Show the available development tasks.
	@awk 'BEGIN {FS = ":.*## "; printf "Usage: make <target> [HOST=127.0.0.1] [PORT=3435]\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Install system-level R and Pandoc prerequisites on macOS.
	@if command -v '$(R)' >/dev/null 2>&1 && command -v pandoc >/dev/null 2>&1; then \
		printf 'R and Pandoc are already installed.\n'; \
	elif command -v brew >/dev/null 2>&1; then \
		printf 'Installing R and Pandoc with Homebrew...\n'; \
		brew install r pandoc; \
	else \
		printf '%s\n' 'R and/or Pandoc are missing and Homebrew is unavailable.' 'Install both tools for your operating system, then run make setup again:' '  R:      https://cran.r-project.org/' '  Pandoc: https://pandoc.org/installing.html'; \
		exit 1; \
	fi

$(R_LIBRARY):
	@mkdir -p '$@'

doctor: $(R_LIBRARY) ## Verify that R, Workbench packages, and Pandoc are available.
	@if ! command -v '$(R)' >/dev/null 2>&1; then printf 'R is missing; run make setup to install the development prerequisites.\n'; exit 1; fi
	@$(R) $(R_FLAGS) -e 'required <- c("sandpaper", "varnish"); missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("Missing Workbench package(s): ", paste(missing, collapse = ", "), "; run make install", call. = FALSE); if (!requireNamespace("rmarkdown", quietly = TRUE) || !rmarkdown::pandoc_available()) stop("Pandoc is missing; install Pandoc or use the development container", call. = FALSE); cat("R: ", R.version.string, "\nSandpaper: ", as.character(utils::packageVersion("sandpaper")), "\nVarnish: ", as.character(utils::packageVersion("varnish")), "\nPandoc: ", as.character(rmarkdown::pandoc_version()), "\n", sep = "")'

install: bootstrap $(R_LIBRARY) ## Install the Carpentries Workbench R package and its dependencies.
	@$(MAKE) --no-print-directory _install

_install:
	@$(R) $(R_FLAGS) -e 'required <- c("sandpaper", "varnish"); missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) { install.packages(missing, lib = Sys.getenv("R_LIBS_USER"), repos = c(carpentries = "https://carpentries.r-universe.dev", CRAN = "https://cloud.r-project.org")) } else { cat("Workbench packages are already installed.\n") }'

deps: doctor ## Restore the lesson dependency cache without changing its lockfile.
	@$(R) $(R_FLAGS) -e 'sandpaper::manage_deps(path = ".", profile = "lesson-requirements", snapshot = FALSE, quiet = FALSE)'

snapshot: doctor ## Update the dependency lockfile after lesson requirements change.
	@$(R) $(R_FLAGS) -e 'sandpaper::manage_deps(path = ".", profile = "lesson-requirements", snapshot = TRUE, quiet = FALSE)'

setup: ## Bootstrap the complete local workshop development environment.
	@$(MAKE) --no-print-directory install
	@$(MAKE) --no-print-directory deps

check: doctor ## Validate lesson structure and content.
	@$(R) $(R_FLAGS) -e 'sandpaper::check_lesson(path = ".")'

build: doctor ## Incrementally build the static site without opening a browser.
	@$(R) $(R_FLAGS) -e 'sandpaper::build_lesson(path = ".", preview = FALSE, quiet = FALSE)'
	@$(R) $(R_FLAGS) -f scripts/apply-site-theme.R --args '$(CURDIR)'

rebuild: doctor ## Rebuild the complete site, ignoring cached output.
	@$(R) $(R_FLAGS) -e 'sandpaper::build_lesson(path = ".", rebuild = TRUE, preview = FALSE, quiet = FALSE)'
	@$(R) $(R_FLAGS) -f scripts/apply-site-theme.R --args '$(CURDIR)'

dev: doctor ## Start the hot-reload preview server (HOST and PORT are configurable).
	@printf 'Previewing at http://%s:%s (press Ctrl-C to stop)\n' '$(HOST)' '$(PORT)'
	@$(R) $(R_FLAGS) -f scripts/serve.R --args '$(CURDIR)' '$(HOST)' '$(PORT)'

clean: doctor ## Remove generated site output and the lesson build cache.
	@$(R) $(R_FLAGS) -e 'sandpaper::reset_site(path = ".")'

all: check build ## Validate and build the lesson.

TASKS = help bootstrap doctor install deps snapshot setup check build rebuild dev clean all _install

.PHONY: $(TASKS)
