---
title: 'Reference'
---

## Concept map

| Python idea | Rust counterpart | Important difference |
|:--|:--|:--|
| variable binding | `let`, `let mut` | Rust is immutable by default. |
| `list[T]` | `Vec<T>` or `&[T]` | Use a slice when a function only borrows values. |
| `dict[K, V]` | `HashMap<K, V>` | Key and value types are fixed. |
| single- or double-quoted `str` | `&str`, `String`, or `char` | Rust separates borrowed text, owned text, and one Unicode scalar value. |
| `lambda value: expression` | `|value| expression` | Rust closures may contain blocks and capture by borrow, mutable borrow, or value. |
| explicit `return value` | a tail expression or `return value;` | A Rust tail expression has no semicolon; `return` is useful for an early exit. |
| `None` / optional value | `Option<T>` | Absence is explicit in the type. |
| raised exception | `Result<T, E>` | Convert expected failures to Python exceptions. |
| decorator | attribute or attribute macro | Python decorators receive runtime objects; Rust attributes are compiler inputs. |
| duck-typed behavior | trait | A trait is a compile-time behavior contract. |
| class hierarchy / union | `struct` and `enum` | Enums model a closed set of variants. |
| context-managed resource | owner plus `Drop` | Cleanup occurs when the owner leaves scope. |

## Boundary annotations

| Annotation or type | Purpose |
|:--|:--|
| `#[pyfunction]` | Expose a Rust function to Python. |
| `#[pyclass]` | Define a Rust-backed Python class. |
| `#[pymethods]` | Add Python-visible methods to a `#[pyclass]`. |
| `#[pymodule]` | Initialize the native Python module. |
| `PyResult<T>` | Return a value or a Python exception. |
| `PyValueError::new_err(...)` | Construct a Python `ValueError`. |

## Assurance map

| Tool or technique | Use it for | Do not mistake it for |
|:--|:--|:--|
| [Hypothesis][hypothesis] or [Proptest][proptest] | Generating and shrinking examples for invariants | Proof over every possible input |
| [Miri][miri] | Detecting many forms of undefined behavior on executed Rust paths | A soundness proof or business-logic verifier |
| [Kani][kani] | Model-checking assertions and contracts in a proof harness | Unbounded verification of unsupported code |
| [Verus][verus] | Proving Rust-like specifications with proof code and SMT solving | Drop-in verification of every Rust feature |
| [Creusot][creusot] | Proving contracts on a supported safe-Rust subset through Why3 | A replacement for boundary and packaging tests |
| [Prusti][prusti] | Exploring contract verification through Viper | A verifier for all Rust and library features |
| [Aeneas][aeneas] | Translating supported safe Rust into functional proof-assistant code | An automatic proof with no proof-assistant work |

These tools are optional and are not installed by the workshop environment.
Choose one only after naming the property and why ordinary tests are
insufficient.

## Commands used in the workshop

```bash
# Install acorn-py's locked Python environments and toolchains.
pixi install --locked -e py310
pixi install --locked -e py313

# Build and install the extension for iterative development.
pixi run -e py313 develop

# Run the public Python API tests on both supported versions.
pixi run -e py310 test
pixi run -e py313 test

# Check Rust and Python code, then test the built wheel.
pixi run -e py313 lint
pixi run -e py313 wheel-smoke
```

On macOS and Linux, the reference project's `make check`, `make test`, and
`make wheel-smoke` targets wrap those commands.

## `acorn-py` naming map

| Name | Role |
|:--|:--|
| `acorn-py` | Repository, Python distribution, and Rust crate name |
| `acorn` | Python extension import name |
| `acorn.schema.validate` | Python namespace for validator and formatter functions |
| `acorn.schema.pid` | Python namespace for Rust-backed identifier classes |
| `acorn-lib`, `acorn-schema` | Pinned upstream Rust dependencies |

## Glossary

**expression**
: Rust code that produces a value. A block's final expression becomes its
  value when it has no semicolon. Adding a semicolon discards that value.

**`?` operator**
: Propagates an `Err` or `None` by returning early from the current function.
  It does not panic. Use it when delegating failure to the caller is the chosen
  error policy.

**borrow**
: Temporary access to a value without taking ownership. A borrow is expressed
  as a reference such as `&T` or `&mut T`.

**`char`**
: One Unicode scalar value in Rust. A displayed grapheme can contain more than
  one `char`.

**closure**
: A callable value that may capture its surrounding environment. Rust writes a
  closure as `|arguments| expression`; Python uses `lambda` for its
  single-expression anonymous functions.

**Cargo**
: Rust's build tool and package manager. Rust packages are called crates.

**extension module**
: A compiled native library that Python can import as a module.

**lifetime**
: A relationship the Rust compiler uses to verify that references cannot
  outlive the values they borrow.

**Maturin**
: A build and packaging tool for producing Python packages backed by Rust.

**move**
: Transfer of ownership from one binding or function to another.

**ownership**
: Rust's model for determining which binding is responsible for a value and
  when that value is released.

**PyO3**
: Rust bindings for creating and interacting with Python objects and extension
  modules.

**unit `()`**
: Rust's type and value for “no useful value.” A function without a tail value
  returns `()`; this is similar in purpose, though not identical, to Python's
  `None`.

**Pixi**
: The environment and task runner used by `acorn-py` to select locked Python,
  Rust, Maturin, and test dependencies.

**stable ABI / ABI3**
: A CPython binary interface that lets one compatible extension wheel support
  multiple Python minor versions. `acorn-py` targets `abi3-py310`.

**`&str` / `String`**
: Borrowed and owned UTF-8 text, respectively. Rust string literals normally
  provide `&str`; use `String` when the value must be owned or grow.

**trait**
: A definition of shared behavior that types can implement.

**wheel**
: Python's built-package format. Native wheels are specific to compatible
  Python, operating-system, and architecture combinations.

## Primary documentation

- [The Rust Programming Language][rust-book]
- [Rust by Example][rust-example]
- [PyO3 user guide][pyo3]
- [Maturin user guide][maturin]
- [`acorn-py` reference implementation][acorn-py]
- [Pixi documentation][pixi]
- [Python packaging guide: binary extensions][binary-extensions]

## Prototyping references

- [`todo!`][todo], [`unreachable!`][unreachable], [`assert!`][assert], and
  [`dbg!`][dbg] in the Rust standard library
- [Anyhow][anyhow] for application-level error context
- [rust-analyzer for VS Code][rust-analyzer]
- [Bacon][bacon] for background Rust checks
- [cargo-script][cargo-script] and Cargo's [unstable single-file package
  support][cargo-script-native]
- [The Problem with Clones in Rust - Why Functional Rust is Slower Than You
  Think (And How to Fix It)][clones]
- [Hypothesis][hypothesis] and [Proptest][proptest] for property-based testing
- [Miri][miri] for detecting undefined behavior on executed Rust paths
- [Kani][kani], [Verus][verus], [Creusot][creusot], [Prusti][prusti], and
  [Aeneas][aeneas] for further exploration of software verification

[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
[aeneas]: https://github.com/AeneasVerif/aeneas
[anyhow]: https://docs.rs/anyhow/latest/anyhow/
[assert]: https://doc.rust-lang.org/stable/std/macro.assert.html
[bacon]: https://github.com/Canop/bacon
[binary-extensions]: https://packaging.python.org/en/latest/guides/packaging-binary-extensions/
[cargo-script]: https://crates.io/crates/cargo-script
[cargo-script-native]: https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#script
[clones]: https://hamy.xyz/blog/2026-02_the-problem-with-clones-in-rust
[creusot]: https://creusot.rs/
[dbg]: https://doc.rust-lang.org/stable/std/macro.dbg.html
[hypothesis]: https://hypothesis.readthedocs.io/
[kani]: https://model-checking.github.io/kani/
[maturin]: https://www.maturin.rs/
[miri]: https://github.com/rust-lang/miri/
[pixi]: https://pixi.prefix.dev/latest/
[proptest]: https://proptest-rs.github.io/proptest/proptest/index.html
[prusti]: https://github.com/viperproject/prusti-dev
[pyo3]: https://pyo3.rs/
[rust-analyzer]: https://rust-analyzer.github.io/book/vs_code.html
[rust-book]: https://doc.rust-lang.org/book/
[rust-example]: https://doc.rust-lang.org/rust-by-example/
[todo]: https://doc.rust-lang.org/stable/std/macro.todo.html
[unreachable]: https://doc.rust-lang.org/stable/std/macro.unreachable.html
[verus]: https://verus-lang.github.io/verus/guide/
