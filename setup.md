---
title: Setup
---

Complete this setup before the workshop. We will use [`acorn-py`][acorn-py] as
one continuous example: first as a Python-facing identifier-validation API,
then as a Rust library exposed through PyO3, and finally as a tested wheel built
with Maturin.

The completed `acorn-py` repository is our reference implementation. During the
workshop we will build a smaller teaching version of it one layer at a time.

Plan 20 to 30 minutes for the first setup. Pixi and Cargo must download the locked
Python packages, Rust toolchain, and Rust crates before the first build.

## What you need to install

Install these system-level tools:

- `Git`, to clone `acorn-py` and fetch its pinned ACORN Rust dependencies;
- `Pixi`, which installs the project-specific Python, Rust, Maturin, pytest,
  Ruff, and native build dependencies; and
- a platform linker and build tools, described below.

The locked environment already includes Python, Rust, Maturin, and pytest, so
you do not need to install them or create a separate virtual environment. The
committed `pixi.lock` and `Cargo.lock` files define the workshop environment.

Check Git before continuing:

```console
git --version
```

### Platform build tools

Choose your operating system once. The other operating-system tabs on this page
will follow your selection.

::::::::::::::::::::::::::::::::::::: group-tab

### Windows

Open Windows Terminal and select its PowerShell profile. Run all Windows
commands in this workshop from PowerShell, not Git Bash.

Install Git and the Visual Studio C++ build tools with WinGet:

```powershell
winget install --id Git.Git -e --source winget
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Close and reopen Windows Terminal after both installers finish.

The workshop uses direct `pixi` commands on Windows, so GNU Make is optional.

### Linux

You need Git, Make, a C toolchain, and Perl. For Debian or Ubuntu:

```bash
sudo apt-get update
sudo apt-get install build-essential git perl
```

Use the equivalent packages on another distribution. Pixi supplies the
project's remaining Linux build dependencies, including `pkg-config`, OpenSSL,
and `patchelf`.

### macOS

Install the Xcode Command Line Tools if they are not already present:

```bash
xcode-select --install
```

The installer may report that the tools are already installed; that is fine.

::::::::::::::::::::::::::::::::::::::::::::::::

## Install Pixi

Follow the [official Pixi installation instructions][pixi-install] for your
operating system.

::::::::::::::::::::::::::::::::::::: group-tab

### Windows

Run this command from the PowerShell profile in Windows Terminal:

```powershell
winget install --id prefix-dev.pixi -e --source winget
```

### Linux

```bash
curl -fsSL https://pixi.sh/install.sh | sh
```

### macOS

```bash
curl -fsSL https://pixi.sh/install.sh | sh
```

Homebrew users may instead run `brew install pixi`.

::::::::::::::::::::::::::::::::::::::::::::::::

Open a new terminal so the updated `PATH` takes effect.

Confirm that Pixi is available:

```console
pixi --version
```

## Get the reference project

Choose a directory where you keep source code, then clone `acorn-py`:

```console
git clone https://code.ornl.gov/research-enablement/acorn-py.git
cd acorn-py
```

Do not clone the larger ACORN repository separately. Cargo fetches the
`acorn-lib` and `acorn-schema` crates from the immutable Git revision recorded
in `Cargo.toml` and `Cargo.lock`.

The names intentionally differ:

- the repository and Python distribution are named `acorn-py`;
- the Rust crate is named `acorn-py`; and
- Python code imports the extension as `acorn`.

We will revisit that packaging boundary during the PyO3 episode.

## Create the locked environments

From the root of the cloned `acorn-py` repository, install both supported test
environments:

```console
pixi install --locked -e py310
pixi install --locked -e py313
```

These environments are declared in `pyproject.toml`. At the time this lesson
was prepared, they selected:

| Component | Project requirement |
|:--|:--|
| Python | 3.10 and 3.13 test environments; package minimum 3.10 |
| Rust | 1.96.x |
| Maturin | 1.9.x |
| PyO3 | 0.28.x with `abi3-py310` and `extension-module` |
| pytest | 8.4.x |

Use the versions resolved by `pixi.lock` if its exact patch versions differ
from this table. Do not run `pixi update` or `cargo update` during the workshop.

## Verify the development build

Build the extension into the Python 3.13 development environment and run the
Python test suite:

```console
pixi run -e py313 test
```

The `test` task creates a development environment, runs `maturin develop --uv
--locked`, and then runs pytest. The first invocation also compiles the pinned
ACORN crates and can take several minutes.

Verify the Python-facing API directly:

```console
pixi run -e py313 python -c "from acorn.schema.validate import is_doi; assert is_doi('10.11578/dc.20250604.1'); print('acorn-py is ready')"
```

The command should print `acorn-py is ready`.

## Run the complete pre-workshop check

::::::::::::::::::::::::::::::::::::: group-tab

### Windows

```powershell
pixi lock --check
pixi run -e py313 lint
pixi run -e py310 test
pixi run -e py313 test
pixi run -e py313 wheel-smoke
```

### Linux

```bash
make check
make test
make wheel-smoke
```

### macOS

```bash
make check
make test
make wheel-smoke
```

::::::::::::::::::::::::::::::::::::::::::::::::

This sequence checks formatting and lints, tests the extension with Python 3.10
and 3.13, builds its stable-ABI wheel, installs that wheel into a clean
environment, imports `acorn`, and checks the `acorn-py` distribution metadata.

If a command fails, save the complete output and send it to an instructor
before the workshop.

::::::::::::::::::::::::::::::::::::: callout

### Network and managed-system requirements

Initial setup needs HTTPS access to Conda Forge, PyPI, crates.io, and
`code.ornl.gov`. The build does not require a separate ACORN executable, model,
service, credential, or local ACORN checkout.

On managed or offline systems, ask local support to allow or pre-cache these
dependencies. Linux hosts with an unusual glibc version may also need a
platform-specific Pixi system-requirements setting. Send the output of `pixi
info` to an instructor and leave the committed lockfile unchanged.

::::::::::::::::::::::::::::::::::::::::::::::::

## Optional editor support

Any text editor works. For Visual Studio Code, the Python and rust-analyzer
extensions provide Python completion and inline Rust compiler feedback. Opening
the editor from `pixi shell -e py313` can help it discover the project-managed
tools.

[acorn-py]: https://code.ornl.gov/research-enablement/acorn-py
[pixi-install]: https://pixi.prefix.dev/latest/installation/
