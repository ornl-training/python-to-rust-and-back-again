---
title: 'Instructor Notes'
---

## Workshop shape

The complete lesson contains 180 minutes of active material: 125 minutes of
instruction and 55 minutes of exercises and discussion.

| Episode | Teaching | Exercises | Running total |
|:--|--:|--:|--:|
| There and Back Again | 10 min | 5 min | 15 min |
| Translating Python into Rust | 25 min | 10 min | 50 min |
| Where the Analogy Ends | 20 min | 5 min | 75 min |
| Adding Rust Incrementally | 15 min | 10 min | 100 min |
| Building with PyO3 | 20 min | 10 min | 130 min |
| From Python to Rust and Back Again | 20 min | 10 min | 160 min |
| Practical Guidance and Q&A | 15 min | 5 min | 180 min |

The table describes active workshop time. Schedule breaks in addition to the
three hours when possible. If the room is booked for exactly three hours, take
a 10-minute break after Episode 3 and recover that time by shortening the
Episode 4 seam-ranking report-out and the Episode 7 tool survey. Keep the
hands-on build and boundary-testing exercises intact.

## Three-hour pacing checkpoints

| Clock | Checkpoint |
|:--|:--|
| 0:00 | Open with a concrete decision about whether Rust belongs in the project |
| 0:15 | Begin translating familiar Python constructs |
| 0:50 | Introduce ownership, borrowing, and scoped concurrency |
| 1:15 | Rank candidate Python-Rust seams |
| 1:40 | Build and import the first PyO3 function |
| 2:10 | Exercise conversions, exceptions, and property tests |
| 2:40 | Turn prototype shortcuts into a production plan |
| 3:00 | Finish with one written next step per learner |

Use the exercises as working time, not as optional pauses. In Episode 2, ask
learners to predict the Rust type before revealing it. In Episode 3, have pairs
state whether each function should borrow, mutate, or own. In Episode 4, ask
each pair to defend one seam. During Episode 5, let the build run and use any
failure to practice the diagnostic table. In Episode 6, classify failures by
exception and test layer, then ask learners to state one invariant suitable for
a property test. In Episode 7, have them match a project risk to an assurance
tool before showing the comparison table. These prompts make the allotted time
useful without stretching the lecture.

## Preparation checklist

- Run the learner setup on Windows, macOS, and Linux or recruit helpers who can
  diagnose each platform.
- Clone the current `acorn-py` reference and run `make check`, `make test`, and
  `make wheel-smoke` with its committed Pixi and Cargo lockfiles.
- Confirm that the venue can reach Conda Forge, PyPI, crates.io, and
  `code.ornl.gov`, or pre-cache the locked environments and Rust crates.
- Prepare a clean teaching checkout at every checkpoint listed below so
  learners can recover from native build or editing errors.
- Decide whether learners will type each `acorn-py` binding or receive the next
  checkpoint as a patch.
- Have one realistic benchmark ready; avoid implying Rust is automatically
  faster than idiomatic Python libraries backed by native code.

## Teaching approach

The narrative follows a journey out of familiar Python territory and back to a
Python-facing package. Use the metaphor sparingly alongside precise technical
language.

Use comparisons to help learners begin reading Rust, then explicitly retire the
analogy when teaching ownership. Frame compiler messages as feedback about an
API's resource contract. Learners do not need to master lifetime syntax to
understand why references must remain valid.

During the PyO3 exercise, pair learners when possible. Native toolchain failures
can consume the session; switch a blocked learner to the prepared `acorn-py`
checkpoint after five minutes and diagnose the machine during a break.

Learners are building a representative vertical slice. The reference
implementation provides evidence for architecture and packaging decisions.

## Live-coding checkpoints

Keep a clean project at each checkpoint:

1. Pixi creates the locked Python 3.13 development environment.
2. The distribution name `acorn-py` builds an importable module named `acorn`.
3. `from acorn.schema.validate import is_doi` reaches a Rust validator.
4. A Rust-backed identifier class is registered in `acorn.schema.pid`.
5. A fallible Rust operation raises the intended Python `ValueError`.
6. The Python 3.10 and 3.13 test environments pass.
7. `wheel-smoke` builds, installs, imports, and checks the stable-ABI wheel in a
   clean environment.

## Discussion prompts

- Which boundary crossings in learners' projects would copy the most data?
- Which public Python behaviors must remain unchanged?
- Which prototype shortcuts are acceptable, and how will the team find them
  before release?
- Who will build wheels and respond to Rust-related failures?
- What evidence would persuade the team to keep or remove the Rust component?

## Content development map

Each episode contains an HTML comment marking a natural expansion point. When
adding material, preserve the stated learning objectives and adjust episode
timings. Extend the same `acorn-py` vertical slice across episodes: DOI
validation first, then nested modules, a persistent-identifier class, error
translation, cross-version tests, and a wheel. Keep the public import paths and
tool versions aligned with the completed reference project.
