---
title: "Translating Python into Rust"
teaching: 25
exercises: 10
---

:::::::::::::::::::::::::::::::::::::: questions

- How do familiar Python constructs appear in Rust?
- How do Rust expressions, semicolons, and `return` determine a value?
- How do Python strings and lambdas compare with Rust strings and closures?
- Which differences are syntax, and which change the way we design programs?
- How are Rust attributes different from Python decorators?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Read Rust variables, collections, functions, modules, and loops.
- Explain when a Rust block returns its final expression and when it returns `()`.
- Distinguish `&str`, `String`, `char`, and `.chars()`.
- Read a Rust closure and explain how it captures surrounding values.
- Use `Option` and `Result` to represent missing values and failures.
- Use pattern matching to handle explicit alternatives.
- Distinguish compile-time Rust attributes from runtime Python decorators.

::::::::::::::::::::::::::::::::::::::::::::::::

## Build a first mental map

Rust will feel less foreign when we anchor new syntax to familiar Python ideas.
The comparisons below are starting points; similar syntax can behave
differently.

| Python | Rust | Important difference |
|:--|:--|:--|
| `name = "Bilbo"` | `let name = "Bilbo";` | Rust bindings are immutable by default. |
| `MAX_RETRIES = 3` | `const MAX_RETRIES: u8 = 3;` | Python uses a naming convention; Rust enforces a declared type and compile-time value. |
| `list[int]` | `Vec<i64>` | A Rust vector has one element type. |
| `dict[str, int]` | `HashMap<String, i64>` | Key and value types are explicit. |
| `None` | `Option::None` | Absence is represented in the type. |
| exception | `Result::Err` | Recoverable failure is commonly returned. |
| `for item in items` | `for item in items` | Ownership determines what the loop may consume. |

## Variables, types, and functions

```python
from acorn.schema.validate import is_doi

def count_valid_dois(values: list[str]) -> int:
    return sum(is_doi(value) for value in values)
```

```rust
use acorn_schema::validation::rules;

fn count_valid_dois(values: &[String]) -> usize {
    values
        .iter()
        .filter(|value| rules::doi(value.as_str()).is_ok())
        .count()
}
```

The Rust function accepts a borrowed slice, so callers can provide a view of a
vector without transferring ownership. Its return type records that a count is
never negative. ACORN groups scalar validators under `validation::rules`; each
rule returns a structured `Result`, and this iterator counts the successful
results. The compiler verifies that each call respects this contract.

## Expressions produce values

Most Rust constructs are expressions, including blocks, `if`, and `match`.
The final expression in a block becomes that block's value when it has no
semicolon:

```rust
fn doubled(value: i64) -> i64 {
    value * 2
}

fn describe(valid: bool) -> &'static str {
    if valid {
        "valid"
    } else {
        "invalid"
    }
}
```

Adding a semicolon evaluates an expression and discards its value. The block
then produces the unit value `()`, roughly Rust's “no useful value” type. This
version therefore fails to compile because the signature promises an `i64`:

```rust
fn doubled(value: i64) -> i64 {
    value * 2;
}
```

Use `return` to leave the current function early. Rust permits it for the final
value too, but an unadorned tail expression is the usual style:

```rust
fn checked_double(value: i64) -> Result<i64, String> {
    if value < 0 {
        return Err("value must not be negative".to_string());
    }

    Ok(value * 2)
}
```

Python differs in two ways. An expression on the last line of a normal Python
function is discarded, and a function that reaches the end returns `None`.
Python needs `return value` to send a value to the caller. Python semicolons
only separate statements; adding or removing one does not decide a function's
return value.

| Form | Rust | Python |
|:--|:--|:--|
| Final expression without `;` | Becomes the block's value | Evaluated and discarded in a normal function |
| Expression followed by `;` | Value is discarded; the statement produces `()` | Semicolon is an optional statement separator |
| `return value` | Exits the function explicitly, often for an early path | Exits the function and supplies its value |
| Reaching the end | Returns the tail expression, or `()` if none exists | Returns `None` |

## Strings are UTF-8, but the types differ

Python's single and double quotes create the same `str` type. Choose the form
that follows the project's style or avoids escapes:

```python
single = 'There and Back Again'
double = "There and Back Again"

assert single == double
assert isinstance(single[0], str)
```

Rust uses double quotes for strings and single quotes for one `char`. Its two
main string types express ownership. Single quotes also appear in lifetime
names such as `'a`; context distinguishes a lifetime from a character literal.

```rust
let borrowed: &str = "There and Back Again";
let owned: String = borrowed.to_string();
let letter: char = 'T';
let first: Option<char> = owned.chars().next();
```

| Form | Meaning |
|:--|:--|
| `"text"` | A string literal, normally used as a borrowed `&'static str` |
| `&str` | A borrowed UTF-8 string slice; it does not own or grow the text |
| `String` | Owned, growable UTF-8 text |
| `'T'` | One Unicode scalar value of type `char`, not a one-character string |
| `text.chars()` | An iterator over Unicode scalar values |
| `text.bytes()` | An iterator over the UTF-8 bytes |

Rust does not allow `text[0]`: a UTF-8 character may occupy more than one byte,
so a numeric index would be ambiguous. Use `.chars()` when Unicode scalar
values are the intended unit and `.bytes()` when the encoding bytes are. A
visible user-perceived character can contain several scalar values, so code
that needs grapheme clusters should use a Unicode-segmentation library rather
than assuming that one `char` equals one displayed character.

A function normally accepts `&str` when it only needs to read text and returns
`String` when it creates owned text:

```rust
fn add_prefix(value: &str) -> String {
    format!("doi:{value}")
}
```

## Collections and iteration

```rust
fn positive_squares(values: &[i64]) -> Vec<i64> {
    values
        .iter()
        .filter(|value| **value > 0)
        .map(|value| value * value)
        .collect()
}
```

Iterator chains may look like Python comprehensions, but they remain strongly
typed and are compiled into efficient loops.

## Anonymous functions are closures

Python calls its compact anonymous function a `lambda`. Rust calls the
corresponding construct a closure and places parameters between vertical bars:

```python
lengths = list(map(lambda value: len(value), values))
```

```rust
let lengths: Vec<usize> = values
    .iter()
    .map(|value| value.chars().count())
    .collect();
```

::::::::::::::::::::::::::::::::::::: callout

### Why is it called a lambda?

The name predates Python by decades. In 1932, mathematician Alonzo Church used
the Greek letter lambda in his [lambda calculus][lambda-calculus], a compact
formal notation for creating functions by abstraction and applying them to
arguments. John McCarthy's [original Lisp paper][lisp-paper] used `LAMBDA` in
1960, helping carry the term from mathematical logic into programming-language
vocabulary.

Python keeps `lambda` as the keyword for an anonymous function expression.
Rust uses the term *closure*, which emphasizes that the callable value may
capture part of its surrounding environment. A lambda or closure can still be
assigned to a name; “anonymous” describes how it was created, not whether the
program can refer to it later.

::::::::::::::::::::::::::::::::::::::::::::::::

Python limits a lambda body to one expression. A Rust closure may use either
one expression or a block, and parameter and return types are usually inferred
from the call site. Both languages can capture surrounding values:

```python
suffix = "!"
decorate = lambda value: f"{value}{suffix}"
```

```rust
let suffix = String::from("!");
let decorate = |value: &str| format!("{value}{suffix}");
```

The Python closure looks up the captured name when it is called. Rust decides
whether a closure borrows, mutably borrows, or consumes each captured value
from how the closure uses it. Adding `move` forces capture by value, which is
common when a closure must outlive the current scope or move to another thread.
That capture behavior determines whether the closure implements `Fn`, `FnMut`,
or `FnOnce`.

Use a named function when the operation is reused or deserves its own test.
Closures work well for small, local transformations passed to `map`, `filter`,
thread spawners, and similar APIs.

## Pattern matching and errors

```rust
fn parse_port(raw: &str) -> Result<u16, String> {
    match raw.parse::<u16>() {
        | Ok(port) if port > 0 => Ok(port),
        | Ok(_) => Err("port must be greater than zero".to_string()),
        | Err(error) => Err(format!("invalid port: {error}")),
    }
}
```

`match` makes the successful and unsuccessful paths visible. The `?` operator
can propagate an error when a function does not need to transform it. ACORN's
domain validators use the same shape with `ValidationError`, which preserves a
stable error code separately from its human-readable message.

::::::::::::::::::::::::::::::::::::: callout

### Use `?` for deliberate propagation, not automatic error handling

Use `?` when the current function deliberately delegates a failure to its
caller. Avoid it when this layer has the context to recover, attach a domain
error, or choose a different path; use `match`, `map_err`, or another explicit
transformation instead.

The `?` operator does **not** ignore an error and does **not** panic. On an
`Err`, it returns early with a compatible `Err`; on an `Ok`, it unwraps the
value. A function returning `Result` therefore still has an explicit,
deterministic output. Panics come from operations such as `unwrap()`,
`expect()`, and `panic!()`, not from `?` itself.

Some functional-programming-oriented teams avoid `?` when its early return
hides a branch that matters to the design. They prefer `match` or combinators so
the transformation remains visible and composable. That is a readability
choice, not a requirement of functional programming: deliberate `Result`
propagation with `?` is still typed and non-panicking.

::::::::::::::::::::::::::::::::::::::::::::::::

## Attributes resemble decorators, but run at a different time

Python decorators and Rust attributes both place declarative-looking syntax
above a function, class, or type. That visual similarity is useful for reading
code, but their execution models differ.

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class Doi:
    value: str
```

```rust
#[derive(Clone, Debug, Eq, PartialEq)]
struct Doi {
    value: String,
}
```

Both examples ask tooling to supply common behavior. Python calls `dataclass`
after the class body executes, usually during module import. Rust expands
`derive` while compiling and generates implementations of the named traits;
nothing runs merely because the program starts.

| | Python decorator | Rust attribute |
|:--|:--|:--|
| Syntax | `@decorator` | `#[attribute]` |
| When it acts | When the decorated definition executes | During parsing or compilation |
| What it receives | A runtime object such as a function or class | Source-level input understood by the compiler or a macro |
| Common jobs | Wrap, register, or replace an object | Generate implementations, select tests, configure compilation, or generate binding code |

An outer attribute such as `#[test]` applies to the item that follows. An inner
attribute such as `#![allow(dead_code)]` applies to the item that contains it,
often a module or crate. Later, PyO3 attributes such as `#[pyfunction]` and
`#[pymodule]` will generate Python binding code at compile time. They do not
behave like stacked runtime wrappers, so decorator order is not a reliable
mental model for attribute order.

## Keep modules and tests close to the domain

ACORN organizes identifier implementations under `pid` and scalar rules under
`validation::rules`. Tests sit beside those modules instead of in one distant
integration-test file. A validator test uses small tables and names the value
when an assertion fails:

```rust
use acorn_schema::validation::rules;

#[test]
fn test_is_doi() {
    let values = [
        "10.1000/182",
        "https://doi.org/10.11578/dc.20250604.1",
        "10.11578/dc.20250604.1",
    ];
    values.into_iter().for_each(|value|
        assert!(rules::doi(value).is_ok(), "{value} is NOT a valid DOI")
    );
}
```

In the crate itself, a domain module includes its adjacent tests with
`#[cfg(test)] mod tests;`, so test-only code is absent from normal builds.

::::::::::::::::::::::::::::::::::::: challenge

## Translate a small function

Translate this Python function into Rust. Decide how the return type should
represent the case where no DOI is found.

```python
from acorn.schema.validate import is_doi

def first_doi(values: list[str]) -> str | None:
    for value in values:
        if is_doi(value):
            return value
    return None
```

:::::::::::::::::::::::: solution

```rust
use acorn_schema::validation::rules;

fn first_doi(values: &[String]) -> Option<&str> {
    values
        .iter()
        .find(|value| rules::doi(value.as_str()).is_ok())
        .map(String::as_str)
}
```

`Option<&str>` records that the search may not find a value and borrows the
matching text from the input collection. We will return to that reference when
we discuss ownership and lifetimes.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

<!-- Instructor expansion point: trace validation::rules::doi into the canonical DOI parser in acorn-schema. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Familiar surface syntax can help us begin reading Rust.
- A Rust block can return its final expression; a semicolon discards that
  expression's value, while `return` exits explicitly.
- Python quote style does not change its string type; Rust distinguishes
  borrowed `&str`, owned `String`, and scalar `char` values.
- Rust closures use `|arguments| expression` and capture by borrow, mutable
  borrow, or value according to how they use their environment.
- Rust makes mutability, data types, absence, and recoverable errors explicit.
- The `?` operator propagates a typed failure; it neither handles the failure
  locally nor causes a panic.
- Rust attributes provide compile-time instructions; Python decorators operate
  on runtime objects as definitions execute.
- A slice such as `&[i64]` lets a function inspect sequential data without
  taking ownership of it.

::::::::::::::::::::::::::::::::::::::::::::::::

[lambda-calculus]: https://plato.stanford.edu/entries/lambda-calculus/
[lisp-paper]: https://www-formal.stanford.edu/jmc/recursive.html
