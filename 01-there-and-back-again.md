---
title: "There and Back Again"
teaching: 10
exercises: 5
---

<style>
@font-face {
  font-family: "Ringbearer";
  src:
    local("Ringbearer Medium"),
    local("Ringbearer"),
    url("files/RINGM___.TTF") format("truetype"),
    url("../files/RINGM___.TTF") format("truetype");
  font-display: swap;
  font-style: normal;
  font-weight: 500;
}

body:not(:has(#aio-01-there-and-back-again))
  .main-content .lesson-content > h1:first-child {
  font-family: "Ringbearer", "Mulish", sans-serif;
  font-kerning: normal;
  font-weight: 500;
}

.rust-python-projects {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: center;
  list-style: none;
  margin: 1.75rem 0;
  padding-left: 0;
}

.rust-python-projects li {
  flex: 0 1 8.5rem;
}

.rust-python-projects figure {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  justify-content: flex-end;
  margin: 0;
  text-align: center;
}

.rust-python-projects img {
  display: block;
  height: 5rem;
  max-width: 12rem;
  object-fit: contain;
  width: 100%;
}

.episode-banner {
  border-radius: 0.75rem;
  margin: 1rem 0 2rem;
  overflow: hidden;
}

.episode-banner img {
  aspect-ratio: 3 / 1;
  display: block;
  object-fit: cover;
  width: 100%;
}

</style>

<figure class="episode-banner">
  <img
    src="files/hobbit-hole-acorn-banner.png"
    alt="A round-doored hillside dwelling at sunset opposite a large acorn resting in moss."
  >
</figure>

:::::::::::::::::::::::::::::::::::::: questions

- What does Rust add to a successful Python project?
- When is a mixed-language project worth the added complexity?
- Where is Rust already present in the Python ecosystem?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Contrast the strengths and costs of Python and Rust.
- Recognize common motivations for placing Rust behind a Python API.
- Form a specific hypothesis before optimizing or migrating code.

::::::::::::::::::::::::::::::::::::::::::::::::

## Two languages, two jobs

Python optimizes for developer momentum: expressive code, a rich ecosystem, and
a fast path from experiment to working software. Rust optimizes for control and
confidence: predictable performance, memory safety without a garbage collector,
and errors caught before deployment.

Ask where each language creates the most value in the project.

| Python is often strongest at | Rust is often strongest at |
|:--|:--|
| orchestration and application logic | tight compute-heavy loops |
| exploration and rapid iteration | predictable memory and latency |
| broad scientific and web ecosystems | safe low-level or concurrent work |
| approachable, flexible APIs | standalone native libraries |

## Reasons to cross the boundary

Common motivations include a measured performance bottleneck, memory pressure,
parallel work constrained by Python's runtime, reuse of an existing Rust crate,
or a need for stronger guarantees in a small critical component.

Crossing the boundary has costs. Native builds complicate packaging, values
must be converted between language runtimes, and maintainers need enough Rust
knowledge to support the result. A benchmark and an explicit goal give the
decision a foundation.

## Turn a hunch into a decision

Before writing Rust, record three things. They keep a promising experiment from
quietly becoming an open-ended rewrite.

| Decision input | Question to answer | ACORN-shaped example |
|:--|:--|:--|
| Baseline | What happens now on representative data? | Record median and slowest-case time for a realistic batch of DOI values. |
| Target | What improvement would matter to users or operators? | Reduce validation time enough to shorten an actual ingest job, not merely a microbenchmark. |
| Cost budget | What added complexity is acceptable? | Support the required wheels without making every Python maintainer debug Rust. |

Measure through the interface users will call. A Rust function may be fast in
isolation while conversion, repeated boundary crossings, or wheel startup
dominates the installed package. The experiment may also succeed without a
speedup: reusing a trusted crate or making memory use more predictable can be a
valid result when that was the stated target.

## Our route: `acorn-py`

Throughout the workshop we will build a representative slice of
[`acorn-py`][acorn-py]. Its Python users work with familiar imports such as:

```python
from acorn.schema.validate import is_doi

assert is_doi("10.11578/dc.20250604.1")
```

Behind that API, PyO3 exposes validation and schema behavior from the Rust
crates `acorn-lib` and `acorn-schema`. This is a credible incremental boundary:
identifier validation is self-contained, the Python contract is easy to test,
and the Rust implementation already exists. The Python package exposes a
selected subset of the Rust APIs.

The completed project also gives us production questions to examine: why the
distribution is named `acorn-py` while the import is `acorn`, why it uses the
CPython stable ABI, and how its wheels are tested on more than one Python
version.

::::::::::::::::::::::::::::::::::::: challenge

## Write the reason before choosing the tool

Think of a Python project you know. Complete this sentence:

> Moving ______ to Rust may improve ______, which we will verify by ______.

Then name one reason that component should remain in Python.

:::::::::::::::::::::::: solution

A useful answer names a narrow component, a measurable outcome, and a test. For
example: "Moving file-format parsing to Rust may reduce import time, which we
will verify with a representative benchmark." Keeping CLI orchestration in
Python may preserve iteration speed and ecosystem integrations.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

## Rust may already be in your environment

Python packages can expose native code while presenting ordinary Python modules
to their users. Projects such as Polars, Pydantic Core, Ruff, uv, and Tokenizers
demonstrate different ways Rust can support Python-facing tools. They show that
a carefully chosen boundary can work well, while each project still needs its
own reason to adopt Rust.

<ul class="rust-python-projects" aria-label="Python projects powered by Rust">
  <li>
    <figure>
      <a href="https://pola.rs/" aria-label="Polars">
        <img src="files/polars-logo.svg" alt="">
      </a>
    </figure>
  </li>
  <li>
    <figure>
      <a href="https://pydantic.dev/" aria-label="Pydantic">
        <img src="files/pydantic-logo.svg" alt="">
      </a>
    </figure>
  </li>
  <li>
    <figure>
      <a href="https://docs.astral.sh/ruff/" aria-label="Ruff">
        <img src="files/ruff-logo.svg" alt="">
      </a>
    </figure>
  </li>
  <li>
    <figure>
      <a href="https://docs.astral.sh/uv/" aria-label="uv">
        <img src="files/uv-logo.svg" alt="">
      </a>
    </figure>
  </li>
  <li>
    <figure>
      <a href="https://huggingface.co/docs/tokenizers/" aria-label="Hugging Face Tokenizers">
        <img src="files/tokenizers-logo.png" alt="">
      </a>
    </figure>
  </li>
</ul>

<!-- Instructor expansion point: benchmark one ACORN validation workload against a Python baseline. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Python and Rust are complementary when each has a clearly defined role.
- Start from a measured need before considering a rewrite.
- The integration boundary and its maintenance cost are part of the design.

::::::::::::::::::::::::::::::::::::::::::::::::

[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
