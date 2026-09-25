---
title: "Where the Analogy Ends"
teaching: 20
exercises: 5
---

:::::::::::::::::::::::::::::::::::::: questions

- What problems are ownership and borrowing designed to prevent?
- How do traits and enums shape Rust APIs?
- What does "fearless concurrency" mean in practice?
- Do Rust's guarantees leave room for exploratory code?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Explain ownership, borrowing, and lifetimes without relying on Python analogies.
- Distinguish Rust enums and traits from superficially similar Python features.
- Connect compile-time checks to safe resource use and concurrency.
- Separate prototyping shortcuts from production error and ownership policies.

::::::::::::::::::::::::::::::::::::::::::::::::

## Ownership is a resource model

Every Rust value has an owner. When that owner goes out of scope, the value is
dropped. A value can move to a new owner, be borrowed immutably by many readers,
or be borrowed mutably by one writer. These rules prevent use-after-free and
data races before the program runs.

```rust
fn label_length(label: &str) -> usize {
    label.len()
}

fn main() {
    let label = String::from("second breakfast");
    let length = label_length(&label);
    println!("{label} has {length} bytes");
}
```

`label_length` borrows the string, so `label` remains available to its owner.

When the borrow checker objects, first ask what the callee needs to do. The
answer usually selects the parameter shape:

| Callee's intent | Typical parameter | Consequence for the caller |
|:--|:--|:--|
| Read for the duration of the call | `&T` | The caller keeps ownership; many immutable borrows may coexist. |
| Change the caller's value | `&mut T` | The caller keeps ownership; only one mutable borrow may exist at a time. |
| Store or consume the value | `T` | Ownership moves unless the type implements `Copy`. |
| Work on an independent duplicate | `T` from `value.clone()` | The caller keeps the original and pays the clone's explicit cost. |

Start with the least authority the function needs. A validator that only reads
text should accept `&str`; taking a `String` would force ownership transfer or
an unnecessary clone.

## Lifetimes describe relationships

Most lifetimes are inferred. When a function returns a reference, an explicit
lifetime may be needed to state which input keeps that reference valid.

```rust
fn choose_longer<'a>(left: &'a str, right: &'a str) -> &'a str {
    if left.len() >= right.len() {
        left
    } else {
        right
    }
}
```

The annotation does not extend either value's lifetime. It gives the compiler a
relationship it can check.

## Enums carry data; traits describe behavior

Rust enums model a closed set of alternatives, and each variant may carry
different data. Pattern matching ensures that every case is considered. Traits
define shared behavior and can be used for generics or dynamic dispatch.

`acorn-schema` makes both ideas concrete. A patent is one type with distinct
granted, application, and publication variants. The `acorn-py` binding matches
those variants and constructs one consistent Python-facing `Patent` object.

```rust
use acorn_schema::pid::patent::{CountryCode, KindCode};
use acorn_schema::pid::{Patent, PersistentIdentifier};

fn kind(patent: &Patent) -> &'static str {
    match patent {
        | Patent::Granted { .. } => "grant",
        | Patent::Application { .. } => "application",
        | Patent::Publication { .. } => "publication",
    }
}
fn main() {
    let patent = Patent::Granted {
        country_code: Some(CountryCode::US),
        kind_code: KindCode::B2,
        serial_number: "7654321".to_string(),
    };
    assert_eq!(kind(&patent), "grant");
    assert_eq!(patent.identifier(), "US 7654321 B2");
}
```

This is the schema crate's real `Patent` enum rather than a workshop-only
facsimile. Importing `PersistentIdentifier` brings its shared methods into
scope; ACORN's identifier types use that trait for behaviors such as
`identifier()` and `schema_uri()`. The exhaustive `match` must be revisited if
the schema adds another patent variant.

## Compile-time guarantees and concurrency

The same ownership rules apply across threads. A value cannot be mutated from
multiple places unless its type provides safe synchronization. Data races are
far harder to express, although other concurrency bugs remain possible.

Scoped threads can safely borrow inputs because Rust proves that every worker
finishes before the scope ends. Each worker below computes its own value, and
the parent combines the results instead of sharing mutable state:

```rust
use std::thread;

fn count_nonempty(left: &[String], right: &[String]) -> Result<usize, &'static str> {
    thread::scope(|scope| {
        let left_worker =
            scope.spawn(|| left.iter().filter(|value| !value.is_empty()).count());
        let right_worker =
            scope.spawn(|| right.iter().filter(|value| !value.is_empty()).count());

        match (left_worker.join(), right_worker.join()) {
            | (Ok(left_count), Ok(right_count)) => Ok(left_count + right_count),
            | _ => Err("a counting worker panicked"),
        }
    })
}
```

The slices are borrowed, not copied. Returning partial counts also avoids a
mutex. Ownership rules prevent either worker from outliving the borrowed data,
while the explicit `Result` records that a worker may panic. Rust still cannot
prevent deadlocks, starvation, or a logically incorrect division of work.

## 😢 Typical misbeliefs

Rust prototypes do not have to look like finished library code. These beliefs
usually come from treating every early decision as permanent:

| Misbelief | A more useful working assumption |
|:--|:--|
| “Memory safety and prototyping just don’t go together.” | Compiler feedback can be part of the experiment. It rules out invalid memory relationships while you test the idea. |
| “Ownership and borrowing take the fun out of prototyping.” | They can interrupt a first draft, so begin with owned values and use a temporary clone when that keeps the experiment moving. Revisit the ownership once the shape is clear. |
| “You have to get all the details right from the beginning.” | Type inference, concrete types, and `todo!()` let you postpone decisions without pretending the unfinished path works. |
| “Rust always requires you to handle errors.” | Rust makes recoverable failure visible with `Result`, but a prototype can deliberately stop with `unwrap()`, `todo!()`, or `unreachable!()`. Production code still needs an intentional policy for user-triggerable failures. |

The prototype's job is to answer a question. Rust makes many shortcuts visible,
which gives us a practical list to revisit before shipping.

::::::::::::::::::::::::::::::::::::: challenge

## Read the borrow checker as a design review

Why should this function fail to compile?

```rust
fn first_word() -> &str {
    let message = String::from("hello from Rust");
    &message[..5]
}
```

How could its API be changed?

:::::::::::::::::::::::: solution

`message` is dropped when the function returns, so the reference would point to
freed memory. Return an owned `String` instead:

```rust
fn first_word() -> String {
    String::from("hello")
}
```

Alternatively, accept an input string and return a slice borrowed from that
input.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

<!-- Instructor expansion point: compare the scoped reduction with a shared Mutex and discuss the ownership tradeoff. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Ownership determines who is responsible for a value and when it is released.
- Borrowing provides temporary access without transferring ownership.
- Lifetimes let the compiler verify relationships between references.
- Enums, traits, and concurrency checks are central Rust design tools.
- Prototypes may defer decisions, provided their shortcuts remain visible and
  are reviewed before production.

::::::::::::::::::::::::::::::::::::::::::::::::
