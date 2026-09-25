---
title: "From Python to Rust and Back Again"
teaching: 20
exercises: 10
---

:::::::::::::::::::::::::::::::::::::: questions

- What happens to strings, paths, objects, and errors at the language boundary?
- How do we choose conversions, exceptions, and tests for a binding contract?
- How can generated examples exercise invariants and round trips?
- How does `acorn-py` test its public Python API?
- What does the stable-ABI wheel smoke test prove?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Select PyO3 argument and return types appropriate for an ACORN binding.
- Map a fallible Rust operation to a meaningful Python exception.
- Distinguish domain, binding-contract, and packaging tests.
- Write a property test for a pure transformation.
- Test Rust-backed behavior through the public Python import path.

::::::::::::::::::::::::::::::::::::::::::::::::

## Data crosses by borrowing, conversion, or extraction

PyO3 can convert many ordinary values between Python and Rust. The choice in a
binding signature documents what happens at the boundary:

- `&str` borrows text for the duration of a call such as `is_doi`;
- `String` owns converted text that must outlive the call;
- `PathBuf` accepts Python path-like input for file operations; and
- a `#[pyclass]` stores Rust data behind a Python-visible object.

Use the least complicated type that expresses the call's needs:

| Rust signature | Python-side input | Boundary effect | Good fit |
|:--|:--|:--|:--|
| `&str` | `str` | Borrow text for this call | A validator that only reads its argument |
| `String` | `str` | Create owned Rust text | A value retained or transformed after extraction |
| `Vec<String>` | A sequence of strings | Build a Rust vector and own its elements | A batch operation with enough work to justify one conversion |
| `PathBuf` | A path-like object | Convert into an owned native path | Reading or writing a document |
| `#[pyclass]` | A Python-visible Rust object | Keep Rust-owned state across calls | A typed identifier with methods and invariants |

`acorn-py` starts with coarse operations. One call validates a complete
identifier or reads a complete research-activity document. It does not ask
Python to cross the native boundary once per byte or once per validation rule.

Convenient conversion can still allocate or copy. Measure realistic calls
before redesigning an interface around more complex borrowed-buffer APIs.

## Turn expected failures into Python exceptions

An invalid identifier naturally returns `false`, but a formatter or file read
can fail with information callers need. `PyResult<T>` lets the binding return a
value or raise a Python exception:

```rust
use acorn_schema::validation;
use pyo3::exceptions::PyValueError;
use pyo3::prelude::*;

#[pyfunction]
fn format_phone_number(value: &str) -> PyResult<String> {
    validation::format_phone_number(value).map_err(|error|
      PyValueError::new_err(error.to_string())
    )
}
```

The public Python contract is now explicit:

```python
import pytest
from acorn.schema.validate import format_phone_number

def test_invalid_phone_number():
    with pytest.raises(ValueError, match="Unable to format"):
        format_phone_number("not a phone number")
```

The schema function returns ACORN's structured `ValidationError`; converting
it to text uses its human-readable message while PyO3 supplies the Python
exception type. Do not use panics to handle expected domain failures. Return
Rust `Result` values and translate them deliberately at the boundary.

## Choose exceptions by caller action

An exception is part of the Python API. Choose it according to what a caller
can do next, rather than according to the Rust type that happened to fail:

| Failure | Python result | Why |
|:--|:--|:--|
| Invalid domain value | `ValueError` or a domain-specific subclass | The caller can change the value |
| Wrong Python argument type | PyO3's generated `TypeError` | The caller violated the function signature |
| Missing or unreadable file | An appropriate `OSError` subclass | Existing Python code already understands file failures |
| Broken internal invariant | An internal error to fix | User input should not trigger a Rust panic |

Keep the full cause for logs or exception chaining when it helps diagnosis, but
make the public message stable enough for a person to act on it. Tests should
usually assert the exception class and a meaningful fragment, not every word of
an implementation detail.

## Test three layers

No single test proves that the whole extension works:

| Layer | What it proves | Example failure it localizes |
|:--|:--|:--|
| Rust unit test | Domain logic and invariants | DOI validation accepts an invalid value |
| Python contract test | Imports, conversions, values, and exceptions | `is_doi` is registered under the wrong module |
| Clean-wheel smoke test | Distribution metadata, ABI tags, and installed artifact | The development build works but the wheel omits the extension |

Keep the fast Rust tests close to the implementation, then use a smaller set of
Python tests at the public path. Finish with at least one clean install because
an editable or development environment can hide missing files and stale native
artifacts.

## Generate examples from invariants

Example-based tests preserve known behavior. Property-based tests describe a
rule and ask a test runner to generate many inputs that might break it. When a
failure is found, tools such as [Hypothesis][hypothesis] for Python and
[Proptest][proptest] for Rust shrink the input toward a smaller counterexample.

Normalization, parsing, and serialization often have useful properties:

- normalizing twice produces the same value as normalizing once;
- parsing a serialized value reconstructs an equivalent value;
- formatting a valid identifier produces another valid identifier; and
- a batch operation agrees with applying the scalar operation to every item.

The same idempotence property can be expressed on either side of the boundary.
In Python:

```python
from hypothesis import given
from hypothesis import strategies as st

def normalize_identifier(raw: str) -> str:
    return raw.strip()

@given(st.text())
def test_normalization_is_idempotent(raw: str):
    once = normalize_identifier(raw)
    assert normalize_identifier(once) == once
```

In Rust:

```rust
use proptest::prelude::*;

fn normalize_identifier(raw: &str) -> String {
    raw.trim().to_string()
}

proptest! {
    #[test]
    fn normalization_is_idempotent(raw in ".*") {
        let once = normalize_identifier(&raw);
        prop_assert_eq!(normalize_identifier(&once), once);
    }
}
```

Keep the smallest failing example as a regular regression test. At a migration
boundary, a differential property can send the same generated values to the
old Python implementation and the new Rust-backed implementation. That checks
compatibility over more cases than a hand-written table, but it still samples
inputs; it is evidence, not a proof.

## Test the public path and the build artifact

Python regression tests protect the names, conversions, return values, and
exceptions users observe:

```python
from acorn.schema.validate import is_doi

def test_is_doi():
    assert is_doi("10.11578/dc.20250604.1")
    assert not is_doi("totally invalid string")
```

Run the Python-facing suite in both supported environments:

```bash
pixi run -e py310 test
pixi run -e py313 test
```

Test the distributable artifact as well as the development install:

```bash
pixi run -e py313 wheel-smoke
```

The smoke task builds the locked release wheel, installs it into a clean
environment, imports `acorn`, and verifies that the installed distribution is
`acorn-py` at the expected version.

::::::::::::::::::::::::::::::::::::: challenge

## Test a complete round trip

Add Python tests for the successful and failing paths of
`format_phone_number`. Then add a validator test that imports `is_orcid` from
`acorn.schema.validate`. Which assertions protect the Rust behavior, and which
protect the cross-language contract?

:::::::::::::::::::::::: solution

The formatted value and validation booleans describe domain behavior. The
import path, accepted Python argument types, `ValueError` class, and exception
message describe the Python-Rust contract. Python-facing regression tests should
exercise both: packaging and exception translation can change what callers
observe even when the Rust function is correct.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

<!-- Instructor expansion point: add ResearchActivity.read to demonstrate PathBuf extraction and nested pyclasses. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Binding signatures reveal whether values are borrowed, owned, converted, or
  stored in Rust-backed Python objects.
- Expected Rust failures should become intentional Python exceptions.
- Layered tests make domain, binding, and packaging failures easier to locate.
- Property tests generate and shrink examples for invariants, round trips, and
  comparisons between the Python and Rust implementations.
- Test the real `acorn.schema` import paths on every supported Python version.
- A clean wheel smoke test catches packaging failures a development import can
  miss.

::::::::::::::::::::::::::::::::::::::::::::::::

[hypothesis]: https://hypothesis.readthedocs.io/
[proptest]: https://proptest-rs.github.io/proptest/proptest/index.html
