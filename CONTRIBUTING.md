# Contributing

Contributions that make **From Python to Rust and Back Again** more accurate,
teachable, and approachable are welcome. Useful contributions include:

- reports from learners who tried the setup on Windows, macOS, or Linux;
- corrections to Python, Rust, PyO3, or Maturin examples;
- exercises and explanations aligned with an existing learning objective;
- instructor notes based on a real delivery; and
- accessibility, wording, or navigation improvements.

Everyone participating in this project must follow the
[Code of Conduct](CODE_OF_CONDUCT.md). By contributing, you agree that your
work may be redistributed under the licenses in [LICENSE.md](LICENSE.md).

## Report a problem or suggest an improvement

Open an issue in the [lesson repository][repository]. Include the page or
episode, what you expected, what happened, and enough version information to
reproduce software or build problems. Learner reports are especially valuable;
please do not wait until you know the solution.

For security-sensitive or private conduct matters, use the reporting route in
the [Code of Conduct](CODE_OF_CONDUCT.md) instead of a public issue.

## Propose a change

1. Create a focused branch from `main`.
2. Edit the Markdown source rather than files under `site/`.
3. Keep additions within the scope of the episode's learning objectives. If new
   material needs teaching time, note what should be shortened or removed.
4. Run the local checks.
5. Open a pull request describing the learner need and how the change was
   verified.

The project follows the [Carpentries generative AI contributions policy][ai].
Disclose generated material as required by that policy and verify technical
claims and code before submitting them.

## Local checks

With R and The Carpentries Workbench installed, run:

```bash
make check
make build
```

Use `make dev` while editing to start a preview that rebuilds automatically.
Run `make help` for dependency setup, clean rebuild, and diagnostic targets.

For changes to [`acorn-py`][acorn-py] code excerpts, verify them in a checkout
of the reference project and run its contributor checks:

```bash
make check
make test
make wheel-smoke
```

The reference project uses Pixi to provide Python, Rust, Maturin, and the test
tools. Keep snippets compatible with its committed `Cargo.lock`, `pixi.lock`,
and `pyproject.toml` rather than testing against unrelated global toolchains.

Do not commit generated website files from `site/`.

[ai]: https://docs.carpentries.org/policies/genai-policy.html
[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
[repository]: https://github.com/ornl-training/python-to-rust-and-back-again
