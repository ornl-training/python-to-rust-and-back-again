---
site: sandpaper::sandpaper_site
---

Python makes it easy to turn an idea into useful software. Rust requires more
explicit choices and can provide speed, predictable resource use, and strong
compile-time guarantees. This workshop shows how to add Rust at a carefully
chosen boundary in an existing Python codebase.

Starting from familiar scripts and notebooks, the workshop examines where a
direct translation into Rust stops working. We will build a teaching-sized
version of [`acorn-py`][acorn-py] with [PyO3][pyo3] and [Maturin][maturin] and
see where Rust already appears in the Python ecosystem.

## Who is this workshop for?

This workshop is for Python developers who are comfortable writing functions,
using collections, importing packages, and working in a terminal. No previous
Rust or systems-programming experience is required.

The lesson is especially useful if you want to:

- speed up a focused part of a Python application;
- make resource-heavy or concurrent code more predictable;
- distribute native functionality behind a familiar Python API; or
- understand the tradeoffs behind the growing number of Rust-backed Python
  packages.

## Learning outcomes

By the end of the workshop, you will be able to:

- relate common Python constructs, including strings and anonymous functions,
  to their Rust counterparts;
- explain ownership, borrowing, traits, and compile-time guarantees in practical
  terms;
- identify a suitable boundary for introducing Rust into an existing Python
  project;
- expose Rust functions and types to Python with PyO3;
- build and install an extension module with Maturin;
- move data and errors across the Python-Rust boundary and test both sides; and
- choose between example tests, property tests, Miri, model checking, and
  proof-oriented verification for a specific engineering risk.

## The worked example

`acorn-py` exposes selected APIs from the Rust crates `acorn-lib` and
`acorn-schema` as the Python module `acorn`. We begin with the familiar Python
contract `from acorn.schema.validate import is_doi`, trace identifier validation
into Rust, add PyO3 functions and classes, translate failures into Python
exceptions, and finish by testing a stable-ABI wheel.

The completed project contains more bindings than can be taught in one
workshop. Our incremental build follows its real architecture and tooling while
concentrating on a representative path: validator function, nested module,
Rust-backed identifier type, error mapping, tests, and packaging.

The seven episodes provide 180 minutes of active instruction, exercises, and
discussion. Complete the setup before the session so the three hours can focus
on design decisions and a working Python-to-Rust vertical slice.

## The journey

| Stage | Focus | Destination |
|:--|:--|:--|
| There and Back Again | Why combine Python and Rust? | A grounded reason to use both |
| Translating Python into Rust | Familiar syntax and concepts | A first mental map |
| Where the Analogy Ends | Ownership, borrowing, traits, and concurrency | Rust's distinct value |
| Adding Rust Incrementally | Preserve `acorn.schema.validate` | A narrow `acorn-py` boundary |
| Building with PyO3 | Bind ACORN validators and types | Working `acorn` imports |
| Crossing the Boundary | Data, errors, and tests | A tested stable-ABI extension |
| Practical Guidance | Tradeoffs, assurance tools, next steps, and Q&A | A route home |

## Why the boundary stays narrow

Rust adds a compiler toolchain, a native build, and a cross-language boundary.
The workshop considers it only for focused work that may justify those costs
and preserves a Pythonic interface throughout.

Start with the [Setup instructions](learners/setup.md), then follow the episodes
in order. Keep the completed `acorn-py` checkout as a reference while building
the teaching version at each checkpoint.

[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
[maturin]: https://www.maturin.rs/
[pyo3]: https://pyo3.rs/
