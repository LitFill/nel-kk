# Koka Non-Empty List Library

A type-safe non-empty list implementation for the Koka programming language.

## Overview

Provides `nonempty : Type -> Type` — a list guaranteed to contain at least one element. The head is always present; the tail is a regular `list<a>` that may be empty.

Operations preserve the non-empty invariant where possible (e.g., `append`, `map`, `sort`), while functions that may produce empty results return `list<a>` or `maybe<a>` as appropriate.

## API

```koka
module nonempty

// Construction
pub fun single(x : a) : nonempty<a>
pub fun cons(x : a, ne : nonempty<a>) : nonempty<a>
pub fun (<::)(x, ne) : nonempty<a>           // right-associative, precedence 5

// Conversion
pub fun list(ne : nonempty<a>) : list<a>
pub fun maybe/list(mne : maybe<nonempty<a>>) : list<a>

// Properties
pub fun length(ne : nonempty<a>) : int       // ≥ 1
pub fun last(ne : nonempty<a>) : a
pub fun init(ne : nonempty<a>) : list<a>

// Deconstruction
pub fun uncons(ne : nonempty<a>) : (a, maybe<nonempty<a>>)
pub fun unsnoc(ne : nonempty<a>) : (maybe<list<a>>, a)

// Transformation
pub fun map(ne : nonempty<a>, f : a -> e b) : e nonempty<b>
pub fun map-indexed(ne : nonempty<a>, f : (int, a) -> e b) : e nonempty<b>
pub fun append(n : nonempty<a>, m : nonempty<a>) : nonempty<a>
pub fun (++)(n : nonempty<a>, m : nonempty<a>) : nonempty<a>
pub fun list/append(ne : nonempty<a>, xs : list<a>) : nonempty<a>
pub fun list/prepend(xs : list<a>, ne : nonempty<a>) : nonempty<a>
pub fun concat(nes : nonempty<nonempty<a>>) : nonempty<a>
pub fun reverse(ne : nonempty<a>) : nonempty<a>
pub fun intersperse(ne : nonempty<a>, a : a) : nonempty<a>

// Folds & scans
pub fun foldl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e b
pub fun foldl1(ne : nonempty<a>, f : (a, a) -> e a) : e a
pub fun foldr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e b
pub fun foldr1(ne : nonempty<a>, f : (a, a) -> e a) : e a
pub fun scanl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e nonempty<b>
pub fun scanr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e nonempty<b>

// Queries
pub fun find(ne : nonempty<a>, pred : a -> e bool) : e maybe<a>
pub fun filter(ne : nonempty<a>, pred : a -> e bool) : e list<a>
pub fun all(ne : nonempty<a>, pred : a -> e bool) : e bool
pub fun any(ne : nonempty<a>, pred : a -> e bool) : e bool

// Sorting
pub fun sort(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e nonempty<a>
pub fun on/sort(ne : nonempty<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e nonempty<a>
```

## Usage via Nix Flake

### As a dependency

```nix
{
  inputs.nonempty.url = "github:youruser/non-empty-list";

  outputs = { self, nixpkgs, nonempty, ... }: {
    packages.x86_64-linux.my-koka-app = pkgs.stdenv.mkDerivation {
      pname = "my-koka-app";
      version = "0.1.0";

      nativeBuildInputs = [ nixpkgs.koka ];

      buildPhase = ''
        koka -i ${nonempty.kokaLibraries.nonempty.includePath} my-app.kk -o my-app
      '';
    };
  };
}
```

### Development shell

```bash
nix develop github:youruser/non-empty-list
```

This provides:
- `koka` compiler in PATH
- `KOKA_PATH` extended with the library's include directory
- `nonEmptyLib` environment variable pointing to the library output

Compile your code:

```bash
koka -i $nonEmptyLib/share/koka/3.2.9 my-app.kk -o my-app
```

### Library metadata (for programmatic consumption)

```nix
nonempty.kokaLibraries.nonempty = {
  path = <store-path>;
  includePath = "<store-path>/share/koka/3.2.9";
  libPath = "<store-path>/lib/koka/3.2.9";
  version = "3.2.9";
};
```

## Building locally

```bash
nix build .#nonEmptyLib
```

Outputs:
- `result/share/koka/3.2.9/nonempty.kk` — source module
- `result/lib/koka/3.2.9/nonempty/` — compiled `.c`, `.h`, `.o` files

## Requirements

- Koka compiler ≥ 3.2.9
- C compiler toolchain (for `--target=c` library build)
- Nix with flake support