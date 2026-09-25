---
title: "Adding Rust to Python Incrementally"
teaching: 15
exercises: 10
---

:::::::::::::::::::::::::::::::::::::: questions

- Where should the Python-Rust boundary go?
- How can we preserve an existing Python API?
- How much work should cross the boundary in one call?
- What should stay in Python?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Evaluate a component as a candidate for a Rust implementation.
- Design a narrow, stable, and testable language boundary.
- Preserve a Python-facing API while changing its implementation.
- Protect existing behavior with characterization tests before replacing it.

::::::::::::::::::::::::::::::::::::::::::::::::

## Choose a seam for Rust

A good first Rust component has a clear input and output, meaningful work per
call, limited dependence on Python objects, and tests that already describe its
behavior. Parsers, codecs, validators, algorithms, and self-contained data
transformations are common candidates.

A poor first boundary crosses languages inside a tight Python loop, depends on
many callbacks into Python, or translates a large object graph on every call.

## Keep the public API Pythonic

Start from the import path and behavior callers should keep. For our worked
example, the contract is ordinary Python even though its implementation is a
native extension:

```python
from acorn.schema.validate import is_doi

assert is_doi("10.11578/dc.20250604.1")
assert not is_doi("not an identifier")
```

`acorn-py` is the distribution name shown by package installers, while `acorn`
is the import name and `acorn.schema.validate` is a nested module registered by
the extension. Treat all three names as part of the packaging contract. Callers
can keep using those public names. The internal crate names and pinned Git
revision remain implementation details.

Our first seam is one validator: string in, boolean out. Later checkpoints add
a Rust-backed identifier class and a fallible file-reading operation. That
sequence keeps each boundary narrow enough to test before the next one is added.

## Protect the behavior before replacing the code

A characterization test records what callers observe today, including awkward
cases that a rewrite may be tempted to “fix.” Run the same test against the
Python implementation, the development extension, and eventually the wheel:

```python
import pytest

from acorn.schema.validate import is_doi

@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("10.1000/182", True),
        ("https://doi.org/10.11578/dc.20250604.1", True),
        ("not an identifier", False),
        ("", False),
    ],
)
def test_is_doi_contract(value: str, expected: bool):
    assert is_doi(value) is expected
```

This test intentionally imports the public path rather than a private helper.
It protects the name, accepted Python value, return type, and domain behavior in
one place. Add edge cases from production data before changing the
implementation; invented examples rarely capture every compatibility promise.

## Choose the call granularity

The narrowest function is not always the cheapest boundary. Consider how the
real caller uses it:

| Boundary shape | Advantage | Cost or risk |
|:--|:--|:--|
| `str -> bool` | Simple contract and easy error isolation | A Python loop may make thousands of native calls. |
| `list[str] -> list[bool]` | One crossing amortizes call overhead | Every string still needs extraction, and the whole batch occupies memory. |
| Python callback from Rust | Preserves flexible Python behavior | Repeated callbacks couple the implementation to Python and may constrain parallel work. |

For a batch API, the conceptual Rust shape remains simple and concrete:

```rust
use acorn_schema::validation::rules;

fn are_dois(values: &[String]) -> Vec<bool> {
    values
        .iter()
        .map(|value| rules::doi(value.as_str()).is_ok())
        .collect()
}
```

Do not add batching merely because it sounds faster. Benchmark the scalar and
batch interfaces with realistic inputs, including the conversion performed by
PyO3. Choose the smallest contract that meets the measured target.

## A boundary checklist

- Is the bottleneck measured with representative data?
- Can inputs and outputs be expressed with simple, stable types?
- Do characterization tests describe the public behavior before it changes?
- Is each call substantial enough to justify conversion overhead?
- Can the behavior be tested from both Python and Rust?
- Will the project build wheels for every supported platform and Python version?
- Does the expected benefit justify another language and toolchain?

::::::::::::::::::::::::::::::::::::: challenge

## Find the seam

For a Python package that reads files, validates records, calculates summaries,
and generates plots, choose one first candidate for Rust. Sketch the function
signature at the Python boundary and list one component you would deliberately
leave in Python.

:::::::::::::::::::::::: solution

Parsing or record validation may be a good boundary when it is measurable and
self-contained. Plotting should generally remain in Python so the project keeps
its mature visualization ecosystem and flexible user-facing options.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

<!-- Instructor expansion point: profile a batch of DOI validations through the acorn-py boundary. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Migrate one well-tested, high-value component at a time.
- Minimize language crossings and data conversion.
- Keep the public Python API separate from the native implementation.
- Leaving a component in Python is a valid engineering outcome.

::::::::::::::::::::::::::::::::::::::::::::::::
