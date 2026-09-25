---
title: "Building a Python Extension with PyO3"
teaching: 20
exercises: 10
---

:::::::::::::::::::::::::::::::::::::: questions

- How does `acorn-py` expose Rust functions and nested modules to Python?
- What do PyO3, Maturin, Cargo, and Pixi each provide?
- What happens between `maturin develop` and `import acorn`?
- Why do the distribution, crate, and import names differ?

::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::: objectives

- Identify the roles of Pixi, Cargo, PyO3, and Maturin in `acorn-py`.
- Expose an ACORN validator through `acorn.schema.validate`.
- Build and install the extension in the locked Python 3.13 environment.
- Trace a development build from the task runner to Python's import machinery.

::::::::::::::::::::::::::::::::::::::::::::::::

## The project layers

- `Pixi` selects the locked Python and Rust toolchains and runs project tasks.
- `Cargo` resolves and builds `acorn-lib`, `acorn-schema`, PyO3, and the local
  Rust crate.
- `acorn-schema` separates persistent-identifier types in `pid` from
  structured scalar validators in `validation::rules`.
- `PyO3` defines the native module, functions, classes, and error mappings.
- `Maturin` builds the Rust crate as an installable Python distribution and
  wheel.

The teaching checkpoints retain `acorn-py`'s real `pyproject.toml`,
`Cargo.toml`, `pixi.lock`, and `Cargo.lock`. We reduce `src/lib.rs` to one
validator, then add the remaining boundary pieces incrementally. The completed
checkout from setup remains available for comparison.

## Follow one development build

`pixi run -e py313 develop` is short, but it coordinates several contracts:

| Phase | Tool | What to inspect when it fails |
|:--|:--|:--|
| Select an environment and task | Pixi | The environment, locked dependencies, and task in `pixi.toml` |
| Read the Python build configuration | Maturin | The backend and `[tool.maturin]` settings in `pyproject.toml` |
| Compile the native library | Cargo and `rustc` | Features, imports, and the dependency revision |
| Install the development artifact | Maturin | The extension filename and active Python environment |
| Initialize the imported module | Python and PyO3 | The import name, `#[pymodule]` name, and nested-module registration |

The development install points Python at the compiled extension. Saving
`src/lib.rs` does not rebuild that extension, so run `develop` again after a
Rust change. If an import appears to use the wrong build, verify the interpreter
through the same environment:

```bash
pixi run -e py313 python -c "import sys; print(sys.executable)"
```

## Read the package contract

Three names describe different layers of the same project:

| Name | Where it appears | Meaning |
|:--|:--|:--|
| `acorn-py` | `pyproject.toml` and `Cargo.toml` | Python distribution and Rust crate |
| `acorn` | `[tool.maturin] module-name` | Python import name |
| `acorn.schema.validate` | PyO3 module registration | Public validator namespace |

The project requires Python 3.10 or newer and enables PyO3's `abi3-py310`
feature. A single wheel built against that stable ABI can support multiple
compatible CPython minor versions.

`Cargo.toml` pins `acorn-lib` and `acorn-schema` to one immutable public Git
revision. No local ACORN checkout is needed. Changing that revision requires a
dependency review and falls outside the workshop.

## Expose the first validator

At the first binding checkpoint, `src/lib.rs` contains one Python function and
the module structure needed to preserve the public import path:

```rust
use acorn_schema::validation::rules;
use pyo3::prelude::*;

#[pyfunction]
fn is_doi(value: &str) -> bool {
    rules::doi(value).is_ok()
}
#[pymodule]
#[pyo3(name = "acorn")]
fn acorn_py(module: &Bound<'_, PyModule>) -> PyResult<()> {
    let python = module.py();
    let schema = PyModule::new(python, "schema")?;
    let validate = PyModule::new(python, "validate")?;
    validate.add_function(wrap_pyfunction!(is_doi, &validate)?)?;
    schema.add_submodule(&validate)?;
    module.add_submodule(&schema)?;
    let sys = python.import("sys")?;
    let modules = sys.getattr("modules")?;
    modules.set_item("acorn.schema", schema)?;
    modules.set_item("acorn.schema.validate", validate)?;
    Ok(())
}
```

`#[pyfunction]` makes the Rust function callable by Python.
`wrap_pyfunction!` adds it to the `validate` module, and the `sys.modules`
entries make Python's nested import machinery recognize the public paths.

Read the initializer as five operations: obtain the Python handle, create the
nested modules, wrap and add functions, register the public paths, and return
`Ok(())`. The `?` operators deliberately propagate initialization failures as
Python exceptions because there is no useful local recovery. Propagating an
error is different from ignoring it.

Build the current checkpoint and call it from Python:

```bash
pixi run -e py313 develop
pixi run -e py313 python -c "from acorn.schema.validate import is_doi; print(is_doi('10.11578/dc.20250604.1'))"
```

The command should print `True`. Re-run `develop` after changing Rust code so
the active development environment receives the rebuilt extension.

## Diagnose the layer, not just the symptom

| Symptom | Likely layer | First check |
|:--|:--|:--|
| Rust compiler error | Cargo or Rust | Read the first diagnostic before the cascading errors |
| `ImportError` mentioning `PyInit_acorn` | Module naming | Compare `module-name` with `#[pyo3(name = "acorn")]` |
| `ModuleNotFoundError` for `acorn.schema.validate` | Nested registration | Check both `sys.modules` entries |
| Python still shows old behavior | Development install | Re-run `develop` in the interpreter's environment |
| Development import passes but the wheel fails | Packaging or ABI | Inspect wheel tags and test a clean installation |

Start with the earliest failing layer. Rewriting Rust cannot repair a wrong
Python interpreter, and changing the Python test cannot repair a missing module
initializer.

## Add a class when identity and behavior belong together

A function is enough for a yes-or-no validation. A Rust-backed class is useful
when Python should keep a validated value and ask it for related behavior later.
This teaching-sized class validates once during construction:

```rust
use pyo3::exceptions::PyValueError;

#[pyclass(frozen, module = "acorn.schema.pid")]
struct Doi {
    value: String,
}

#[pymethods]
impl Doi {
    #[new]
    fn new(value: String) -> PyResult<Self> {
        match rules::doi(value.as_str()) {
            | Ok(_) => Ok(Self { value }),
            | Err(error) => Err(PyValueError::new_err(error.to_string())),
        }
    }

    #[getter]
    fn value(&self) -> &str {
        self.value.as_str()
    }

    fn __str__(&self) -> &str {
        self.value.as_str()
    }
}
```

Register it under a sibling `pid` module using the same parent-child and
`sys.modules` pattern as `validate`. Create and attach `pid` before attaching
`schema` to the top-level module:

```rust
let pid = PyModule::new(python, "pid")?;
pid.add_class::<Doi>()?;
schema.add_submodule(&validate)?;
schema.add_submodule(&pid)?;
module.add_submodule(&schema)?;
```

After obtaining `sys.modules`, register all three qualified names:

```rust
modules.set_item("acorn.schema", schema)?;
modules.set_item("acorn.schema.validate", validate)?;
modules.set_item("acorn.schema.pid", pid)?;
```

`frozen` prevents Python callers from replacing Rust-managed fields. The
constructor turns invalid input into `ValueError`, so a successfully created
`Doi` always satisfies its invariant. Prefer a function when no durable state
or behavior justifies a class.

::::::::::::::::::::::::::::::::::::: challenge

## Bind a second validator

Add an `is_orcid(value: &str) -> bool` function using ACORN's canonical ORCID
rule. Register it beside `is_doi`, rebuild, and verify these calls:

```python
from acorn.schema.validate import is_orcid

assert is_orcid("https://orcid.org/0000-0002-2057-9115")
assert not is_orcid("abc-0000-0000-0000")
```

:::::::::::::::::::::::: solution

The binding follows the same shape as the first validator:

```rust
#[pyfunction]
fn is_orcid(value: &str) -> bool {
    rules::orcid(value).is_ok()
}
```

Register it inside `acorn_py`:

```rust
validate.add_function(wrap_pyfunction!(is_orcid, &validate)?)?;
```

Then run `pixi run -e py313 develop` before executing the Python assertions.

:::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::

<!-- Instructor expansion point: compare the teaching Doi class with the completed acorn-py identifier classes. -->

::::::::::::::::::::::::::::::::::::: keypoints

- Pixi makes the workshop toolchain reproducible; Cargo and Maturin build the
  native Python package.
- PyO3 exposes selected ACORN behavior without exposing the whole Rust crate.
- Distribution, import, and nested-module names are separate contracts.
- A build crosses distinct layers; diagnose the earliest layer that fails.
- Use a `#[pyclass]` when validated state and related behavior must persist
  across Python calls.
- The first working boundary is deliberately small: one string in and one
  boolean out.

::::::::::::::::::::::::::::::::::::::::::::::::
