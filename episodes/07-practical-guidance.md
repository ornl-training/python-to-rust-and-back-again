---
title: "Practical Guidance and Q&A"
teaching: 15
exercises: 5
---

:::::::::::::::::::::::::::::::::::::: questions

- How do we take a mixed-language prototype toward production?
- How can we prototype in Rust without designing the whole system first?
- When should we use property testing, Miri, model checking, or deductive verification?
- Which maintenance and packaging questions should be answered early?
- What is the smallest useful next step?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Review a Python-Rust integration for maintainability and distribution risks.
- Use explicit, temporary shortcuts to keep a Rust prototype moving.
- Choose an assurance tool that matches the property and risk being checked.
- Plan one evidence-driven next step for a real project.
- Identify trustworthy routes for continued learning.

::::::::::::::::::::::::::::::::::::::::::::::::

## 🤓 Prototyping tips

A prototype should answer one question quickly. It does not need polished error
types, a deep module tree, or a generic framework. The useful distinction is
between a shortcut that is easy to find later and one that silently becomes
policy.

### Keep momentum

- Use [`todo!()`][todo] for code you have not written yet. Use
  [`unreachable!()`][unreachable] only when the prototype assumes a branch
  cannot occur. Both macros panic if execution reaches them.
- Use `.unwrap()` liberally inside a throwaway spike where a crash is an
  acceptable answer. Before shipping, replace every user-triggerable unwrap
  with deliberate error handling.
- Use `.clone()` to get past an initial ownership problem, then review the
  copies after the data flow settles. [The Problem with Clones in Rust - Why
  Functional Rust is Slower Than You Think (And How to Fix It)][clones]
  demonstrates why unnecessary clones can matter.
- Use [`println!`][println] and [`dbg!`][dbg] to inspect a running experiment.
  Remove noisy output or replace it with project logging before release.
- Use [`assert!`][assert] to record invariants as executable assumptions. For
  critical code, the assurance tools below can check stronger claims, but each
  has its own supported Rust subset and trust assumptions.

This intentionally rough function makes its deferred decisions searchable:

```rust
fn normalize_identifier(raw: Option<String>) -> String {
    let raw = raw.unwrap(); // PROTOTYPE: decide how missing input should fail.
    let candidate = raw.clone(); // PROTOTYPE: revisit ownership and copying.
    dbg!(&candidate);
    assert!(!candidate.is_empty(), "identifier must not be empty");
    match candidate.strip_prefix("doi:") {
        | Some(value) => value.to_string(),
        | None => todo!("support identifiers without a DOI prefix"),
    }
}
```

### Keep the design plain

- Prefer simple, concrete types and let Rust infer local types. Add annotations
  where they explain an API or resolve ambiguity.
- Design through types, but avoid generic types and explicit lifetimes until
  the problem actually requires them.
- Keep the hierarchy flat at first. A `main.rs` or `lib.rs` can sketch the
  eventual layout with declarations such as `mod input;` and `mod output;`.
- Use [Anyhow][anyhow] for convenient error context in an application
  prototype. Keep typed domain errors where callers, a library API, or the
  Python boundary need to distinguish failures.
- Do not optimize the first draft. Establish correct behavior, then benchmark
  the installed release build before removing clones or adding complexity.

### Shorten the feedback loop

- Use an editor that exposes compiler feedback while you type. VS Code with
  [rust-analyzer][rust-analyzer] is a well-supported starting point.
- Use [Bacon][bacon] to keep `check`, `test`, or `clippy` running in the
  background while files change.
- Consider [cargo-script][cargo-script] eventually for small, single-file
  experiments. Cargo also has built-in single-file package support, but that
  feature [remains unstable][cargo-script-native], so neither is a workshop
  prerequisite.

## Match the assurance tool to the question

These tools are complementary, not a ladder in which every project must reach
the last rung. Begin with a precise claim: “normalization is idempotent,” “this
unsafe block has no undefined behavior,” or “the result always satisfies this
postcondition.” Then choose the least costly tool that can answer it.

| Technique or tool | What it does | Important limit |
|:--|:--|:--|
| Unit and integration tests | Run chosen examples through domain and boundary behavior | Cover only the executions supplied by the tests |
| Property testing | Generates examples for an invariant and shrinks failures | Searches the input space; it does not prove the property |
| [Miri][miri] | Interprets executed Rust code and detects many forms of undefined behavior | Checks only the explored executions and is not a formal verifier |
| [Kani][kani] | Model-checks proof harnesses with symbolic, bit-precise values | Proofs are scoped to the harness, model, supported features, and bounds |
| [Verus][verus] | Uses Rust-like specifications, proof code, and SMT solving | Supports a deliberate subset of Rust and requires proof annotations |
| [Creusot][creusot] | Translates annotated safe Rust contracts into Why3 verification conditions | Requires contracts and code within its supported subset |
| [Prusti][prusti] | Checks Rust preconditions, postconditions, and invariants using Viper | It is a prototype verifier with unsupported Rust and library features |
| [Aeneas][aeneas] | Translates a supported safe-Rust subset into pure functional code for proof assistants | The proof is completed in Lean or another backend, outside ordinary Cargo tests |

Property testing is often the easiest next step after example tests. It works
especially well for parsers, round trips, normalization, and agreement between
the Python and Rust implementations. Preserve generated counterexamples as
ordinary regression tests.

Miri belongs earlier than formal proof when a crate contains `unsafe` code or
low-level memory manipulation:

```bash
cargo +nightly miri test
```

A clean Miri run means the executed tests did not trigger the undefined
behavior Miri detects. It does not establish that unexecuted paths are sound,
and platform APIs or FFI may be unavailable under the interpreter. For a PyO3
project, run it on the testable Rust core and keep Python boundary tests as a
separate layer.

Kani proof harnesses resemble property tests, but symbolic values let the model
checker reason about every value represented by the harness. This small example
checks all pairs of `u8` values:

```rust
fn midpoint(left: u8, right: u8) -> u8 {
    let total = u16::from(left) + u16::from(right);
    (total / 2) as u8
}

#[cfg(kani)]
#[kani::proof]
fn midpoint_stays_between_inputs() {
    let left = kani::any::<u8>();
    let right = kani::any::<u8>();
    let result = midpoint(left, right);
    assert!(result >= left.min(right));
    assert!(result <= left.max(right));
}
```

Verus, Creusot, and Prusti express contracts and invariants close to Rust.
Aeneas takes another route: it uses Rust's ownership discipline to translate a
supported safe subset into pure functional definitions for proof assistants,
primarily Lean. These approaches make sense for a small, high-consequence core
with a stable specification. They rarely justify verifying glue code, wheel
metadata, or the Python import path.

Formal verification proves the stated property under the tool's model and
assumptions. A correct proof of the wrong specification is still the wrong
program. Keep example tests for concrete requirements, property tests for broad
input exploration, and Python-facing tests for the cross-language contract.

## Before shipping

- Review every `todo!()`, `unreachable!()`, `unwrap()`, temporary clone, and
  debugging print. Remove it or document why it is still valid.
- Benchmark the installed `acorn-py` wheel against a realistic validation or
  schema workload.
- Keep a Python-level regression suite for the public API.
- Add property tests for important invariants and round trips; consider Miri or
  a verifier when unsafe code, critical invariants, or the cost of failure
  justifies it.
- Build wheels in continuous integration for supported operating systems and
  architectures; use the `abi3-py310` contract across compatible CPython
  versions.
- Decide whether a source build is supported and document the Python 3.10 and
  Rust 1.96 minimums.
- Keep `Cargo.lock`, `pixi.lock`, and the immutable ACORN dependency revision
  under review.
- Check binary size, import time, error messages, and failure behavior.
- Make ownership of both the Python and Rust code explicit within the team.

Before proposing a binding or packaging change to the reference project, run:

```bash
make check
make test
make wheel-smoke
```

## A sensible route forward

1. Profile a production-shaped workload.
2. Choose one narrow component and write characterization tests around it.
3. Build a Rust prototype without changing the public Python API.
4. Compare correctness, speed, memory, build complexity, and maintenance cost.
5. Keep, revise, or remove the prototype based on that evidence.

## Compared with Python: advantages, not guarantees

Rust raises the floor for some kinds of correctness, but the compiler cannot
prove that the program meets its users' needs.

| Tempting claim | What we can responsibly expect |
|:--|:--|
| “Rust does not need extensive testing to transition to production.” | Static checks replace some tests for type shape, ownership, and memory safety. Behavior, integration, packaging, and platform support still need tests. |
| “Rust prototypes already have good performance.” | A straightforward Rust implementation often starts from a useful performance baseline. Measure a release build with production-shaped input before claiming an improvement. |
| “Rust can be refactored almost risk free.” | Compiler-guided refactoring catches many broken dependencies. It cannot catch every semantic or policy change, so characterization and public-API tests still matter. |
| “Rust is easier to maintain.” | Explicit types and exhaustive matching can reduce surprises. Maintenance is easier only when the team can also debug, build, package, and release the Rust component. |

## Questions to bring home

- Is conversion at the boundary dominating the work?
- Can callers tell that the implementation changed?
- What happens on platforms without a pre-built wheel?
- Can another maintainer debug and release both halves of the project?
- Would better Python, NumPy, Cython, Numba, or a service boundary solve the
  problem more simply?

::::::::::::::::::::::::::::::::::::: challenge

## Write your next step

Name one component you might evaluate, one metric that matters, and one reason
to stop the experiment. Share it with a partner or record it in your project
notes.

::::::::::::::::::::::::::::::::::::::::::::::::

## Workshop reference

Use the [lesson reference](../learners/reference.md) for the concept map,
commands, and primary documentation links introduced during the workshop.

<!-- Instructor expansion point: compare acorn-py's CI wheel matrix with the audience's supported platforms. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Production readiness includes packaging, observability, support, and team skills.
- Prototype shortcuts are useful when they are explicit and reviewed before
  release.
- Compiler checks reduce some testing burden; they do not replace behavioral
  and integration tests.
- Property testing explores broad input spaces; Miri and formal verification
  answer narrower questions with different guarantees and constraints.
- Use the integrated package for benchmarks.
- Incremental adoption should remain reversible until evidence supports it.
- The goal is a better Python project.

::::::::::::::::::::::::::::::::::::::::::::::::

[anyhow]: https://docs.rs/anyhow/latest/anyhow/
[assert]: https://doc.rust-lang.org/stable/std/macro.assert.html
[bacon]: https://github.com/Canop/bacon
[cargo-script]: https://crates.io/crates/cargo-script
[cargo-script-native]: https://doc.rust-lang.org/nightly/cargo/reference/unstable.html#script
[clones]: https://hamy.xyz/blog/2026-02_the-problem-with-clones-in-rust
[dbg]: https://doc.rust-lang.org/stable/std/macro.dbg.html
[kani]: https://model-checking.github.io/kani/
[miri]: https://github.com/rust-lang/miri/
[println]: https://doc.rust-lang.org/stable/std/macro.println.html
[prusti]: https://github.com/viperproject/prusti-dev
[creusot]: https://creusot.rs/
[aeneas]: https://github.com/AeneasVerif/aeneas
[rust-analyzer]: https://rust-analyzer.github.io/book/vs_code.html
[todo]: https://doc.rust-lang.org/stable/std/macro.todo.html
[unreachable]: https://doc.rust-lang.org/stable/std/macro.unreachable.html
[verus]: https://verus-lang.github.io/verus/guide/
