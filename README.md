# From Python to Rust and Back Again

Workshop materials for Python developers who want to introduce Rust at a
carefully chosen boundary without rewriting an entire codebase.

The lesson maps familiar Python concepts to Rust, explains where the analogy
ends, and incrementally builds a teaching-sized version of [`acorn-py`][acorn-py]
with PyO3 and Maturin. It is currently in **pre-alpha**: the structure and
teaching path are ready for content development and review.

## Lesson outline

1. There and Back Again
2. Translating Python into Rust
3. Where the analogy ends
4. Adding Rust to Python incrementally
5. Building a Python extension with PyO3
6. From Python to Rust and back again
7. Practical guidance and Q&A

Learners should begin with the [setup instructions](learners/setup.md). Lesson
authors can use the [instructor notes](instructors/instructor-notes.md) for the
teaching schedule and content-development map.

## Build the site locally

This repository uses [The Carpentries Workbench][workbench]. With R and the
Workbench packages installed, start the hot-reload development server with:

```bash
make dev
```

The preview is available at <http://127.0.0.1:3435> and updates when lesson
files are saved. Override the interface or port when needed:

```bash
make dev HOST=0.0.0.0 PORT=8080
```

Other common tasks are:

```bash
make help     # List every target.
make doctor   # Check R, the Workbench packages, and Pandoc.
make check    # Validate the lesson.
make build    # Incrementally build the static site.
make rebuild  # Rebuild without cached output.
make all      # Validate, then build.
```

Run `make setup` on a new machine to install R and Pandoc through Homebrew when
needed, install the Workbench, and provision the lesson dependencies. On Linux
or Windows, install R and Pandoc with the platform's package manager first; the
target will print the relevant installation links when Homebrew is unavailable.
An installed but unlinked Homebrew R formula is detected automatically, so
`brew link r` is not required. R packages are installed into the ignored,
project-local `.r-library/` directory, leaving Homebrew's global library
unchanged. The same Workbench operations can be invoked directly from R:

```r
library(sandpaper)
build_lesson()
serve()
```

## Ringbearer display font

This private workshop bundles [Ringbearer][ringbearer] for its title and main
headings. `make build` and `make rebuild` copy the font into the generated site;
Mulish remains the fallback. The font's terms limit it to private use, so obtain
permission from the author before publishing or distributing the workshop.

## Contributing

Corrections, learner feedback, exercises, and platform-specific setup reports
are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) before opening an issue or
pull request.

[workbench]: https://carpentries.github.io/sandpaper-docs/
[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
[ringbearer]: https://www.dafont.com/ringbearer.font
