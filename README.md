# Koka Non-Empty List Library

A `nonempty<a>` implementation for the [Koka](https://koka-lang.github.io)
programming language.

> [!WARNING]
> The prose in this document is AI-generated. The code, the API, and the Nix
> outputs are not. Verify all claims against `nonempty/nonempty.kk` and
> `flake.nix` before relying on them.

## Overview

`nonempty<a>` is a list that is guaranteed to hold at least one element. It is
represented as a mandatory head plus an optional tail:

```koka
type nonempty<a> :: (V) -> V
```

The head is always present. The tail is an ordinary `list<a>` and may be empty.
This representation makes the non-empty invariant unrepresentable-violating: no
value of the type can encode an empty list.

Operations preserve the invariant where the result is statically non-empty
(`append`, `map`, `sort`, `concat`, `reverse`). Operations that may
legitimately discard every element return a weaker type (`list<a>`,
`maybe<nonempty<a>>`) instead of a `nonempty<a>` that could be empty.

## API

```koka
module nonempty

// Construction
pub fun single(x : a) : nonempty<a> ...
pub fun cons(x : a, ne : nonempty<a>) : nonempty<a> ...
pub fun (<::)(x, ne) : nonempty<a> ...           // right-associative, precedence 5

// Conversion
pub fun list(ne : nonempty<a>) : list<a> ...
pub fun maybe/list(mne : maybe<nonempty<a>>) : list<a> ...

// Properties
pub fun length(ne : nonempty<a>) : int ...       // >= 1
pub fun last(ne : nonempty<a>) : a ...
pub fun init(ne : nonempty<a>) : list<a> ...

// Deconstruction
pub fun uncons(ne : nonempty<a>) : (a, maybe<nonempty<a>>) ...
pub fun unsnoc(ne : nonempty<a>) : (maybe<list<a>>, a) ...

// Transformation
pub fun map(ne : nonempty<a>, f : a -> e b) : e nonempty<b> ...
pub fun map-indexed(ne : nonempty<a>, f : (int, a) -> e b) : e nonempty<b> ...
pub fun append(n : nonempty<a>, m : nonempty<a>) : nonempty<a> ...
pub fun (++)(n : nonempty<a>, m : nonempty<a>) : nonempty<a> ...
pub fun list/append(ne : nonempty<a>, xs : list<a>) : nonempty<a> ...
pub fun list/prepend(xs : list<a>, ne : nonempty<a>) : nonempty<a> ...
pub fun concat(nes : nonempty<nonempty<a>>) : nonempty<a> ...
pub fun reverse(ne : nonempty<a>) : nonempty<a> ...
pub fun intersperse(ne : nonempty<a>, a : a) : nonempty<a> ...

// Folds and scans
pub fun foldl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e b ...
pub fun foldl1(ne : nonempty<a>, f : (a, a) -> e a) : e a ...
pub fun foldr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e b ...
pub fun foldr1(ne : nonempty<a>, f : (a, a) -> e a) : e a ...
pub fun scanl(ne : nonempty<a>, z : b, f : (b, a) -> e b) : e nonempty<b> ...
pub fun scanr(ne : nonempty<a>, z : b, f : (a, b) -> e b) : e nonempty<b> ...

// Queries
pub fun find(ne : nonempty<a>, pred : a -> e bool) : e maybe<a> ...
pub fun filter(ne : nonempty<a>, pred : a -> e bool) : e list<a> ...
pub fun all(ne : nonempty<a>, pred : a -> e bool) : e bool ...
pub fun any(ne : nonempty<a>, pred : a -> e bool) : e bool ...

// Sorting
pub fun sort(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e nonempty<a> ...
pub fun on/sort(ne : nonempty<a>, f : a -> e b, ?cmp : (b, b) -> e order) : e nonempty<a> ...

// Taking and splitting
pub fun take(ne : nonempty<a>, n : int = ne.length) : list<a> ...
pub fun drop(ne : nonempty<a>, n : int = ne.length) : list<a> ...
pub fun split(ne : nonempty<a>, n : int) : (list<a>, list<a>) ...
pub fun take-while(ne : nonempty<a>, pred : a -> e bool) : e list<a> ...
pub fun drop-while(ne : nonempty<a>, pred : a -> e bool) : e list<a> ...
pub fun span(ne : nonempty<a>, pred : a -> e bool) : e (list<a>, list<a>) ...

// Zipping
pub fun zip(n : nonempty<a>, m : nonempty<b>) : nonempty<(a, b)> ...
pub fun zip-with(n : nonempty<a>, m : nonempty<b>, f : (a, b) -> e c) : e nonempty<c> ...
pub fun unzip(ne : nonempty<(a, b)>) : (nonempty<a>, nonempty<b>) ...

// Indexing and lookup
pub fun index-of(ne : nonempty<a>, pred : a -> e bool) : e int ...
pub fun contains(ne : nonempty<a>, x : a) : bool ...
pub fun lookup(ne : nonempty<(k, v)>, pred : k -> e bool) : e maybe<v> ...

// Aggregation
pub fun sum(ne : nonempty<a>) : e a ...
pub fun product(ne : nonempty<a>) : e a ...
pub fun maximum(ne : nonempty<int>) : int ...
pub fun minimum(ne : nonempty<int>) : int ...
pub fun default/maximum(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e a ...
pub fun default/minimum(ne : nonempty<a>, ?cmp : (a, a) -> e order) : e a ...

// Effectful traversal
pub fun foreach(ne : nonempty<a>, action : a -> e ()) : e () ...
pub fun foreach-indexed(ne : nonempty<a>, action : (int, a) -> e ()) : e () ...
pub fun foreach-while(ne : nonempty<a>, action : a -> e maybe<b>) : e maybe<b> ...

// Filtering and mapping
pub fun filter-map(ne : nonempty<a>, pred : a -> e maybe<b>) : e list<b> ...
pub fun find-maybe(ne : nonempty<a>, pred : a -> e maybe<b>) : e maybe<b> ...
pub fun flatmap(ne : nonempty<a>, f : a -> e nonempty<b>) : e nonempty<b> ...
pub fun flatmap-maybe(ne : nonempty<a>, f : a -> e maybe<b>) : e list<b> ...

// Scans without an initial accumulator
pub fun one/scanl(ne : nonempty<a>, f : (a, a) -> e a) : e nonempty<a> ...
pub fun one/scanr(ne : nonempty<a>, f : (a, a) -> e a) : e nonempty<a> ...
pub fun list/scanl(xs : list<a>, z : b, f : (b, a) -> e b) : e list<b> ...
pub fun list/scanr(xs : list<a>, z : b, f : (a, b) -> e b) : e list<b> ...

// List helpers
pub fun list/snoc(xs : list<a>, x : a) : list<a> ...
pub fun list/nonempty(xs : list<a>) : maybe<nonempty<a>> ...
pub fun list/exn/nonempty'(xs : list<a>) : exn nonempty<a> ...
pub fun list/concat(nes : list<nonempty<a>>) : list<a> ...
pub fun list/unsnoc(xs : list<a>) : maybe<(list<a>, a)> ...

// Construction from a seed
pub fun unfoldr(x : b, f : b -> <div|e> (a, maybe<b>)) : <div|e> nonempty<a> ...

// Joining
pub fun join-end(ne : nonempty<string>, end : string) : string ...

// Comparison
pub fun cmp(n : nonempty<a>, m : nonempty<a>, ?cmp : (a, a) -> e order) : e order ...
```

## Installation

The flake exposes three outputs per system.

| Output                            | Purpose                                                                           |
| --------------------------------- | --------------------------------------------------------------------------------- |
| `packages.<system>.nonEmptyLib`   | The built library. Also aliased as `default`.                                     |
| `checks.<system>.tests`           | Builds and runs `nonempty/test.kk` against the library. Run by `nix flake check`. |
| `kokaLibraries.<system>.nonempty` | Resolved paths, for consumption by other flakes.                                  |

`packages` and `kokaLibraries` refer to the same derivation. Prefer
`kokaLibraries` for downstream flakes: it exposes the include and library paths
pre-composed, so a consumer does not have to rebuild the path layout.

```nix
kokaLibraries.x86_64-linux.nonempty = {
  path        = "/nix/store/...-koka-non-empty-0.1.1";
  includePath = "/nix/store/...-koka-non-empty-0.1.1/share/koka/3.2.9";
  libPath     = "/nix/store/...-koka-non-empty-0.1.1/lib/koka/3.2.9";
  version     = "3.2.9";   # Koka version; keys the share/ and lib/ paths
  libVersion  = "0.1.1";   # this library's version
};
```

> [!NOTE]
> `version` is the **Koka** version, not the library version; `libVersion` is
> the library's own. The `share/` and `lib/` paths are keyed by the Koka
> version, so they must be read from these attributes rather than hardcoded.

### Running the tests

```bash
nix flake check
```

This builds the library and then compiles and runs the test suite against that
build, so a regression in this flake cannot pass by accident. To run the tests
directly:

```bash
nix build .#checks.tests
./result/bin/nonempty-test
```

To iterate without building a separate output, use the development shell, where
the module search path is already configured:

```bash
nix develop
koka -o nonempty-test nonempty/test.kk
./nonempty-test
```

Every case in `nonempty/test.kk` uses `assert`, which aborts the process with a
non-zero exit status on failure. Do not replace `assert` with `val _ =`, which
discards the boolean and always passes.

## Consuming the library

### Module resolution

Koka resolves `import nonempty` against a module search path. The library
installs its source to `<includePath>/nonempty.kk`, so `<includePath>` must
appear on the search path. There are two supported ways to add it.

**`--include` flag.** Explicit and reliable; use it in Nix build phases.

```bash
koka -o my-app --include="$(nix eval --raw .#kokaLibraries.x86_64-linux.nonempty.includePath)"
```

**`KOKA_OPTIONS` environment variable.** Equivalent to passing `--include` on
every invocation, so it is the better choice for a development shell.

```bash
export KOKA_OPTIONS="--include=${includePath}"
koka -o my-app src/main.kk
```

> [!IMPORTANT]
> `KOKA_PATH` does **not** work for this purpose. The Koka compiler uses
> `KOKA_PATH` to locate its own core libraries, and does not add its contents to
> the user module search path. A `KOKA_PATH` entry naming the library still
> fails with `could not find module: nonempty`. Use `--include` or
> `KOKA_OPTIONS`.

### Development shell

Add the input and thread the include path through a shell hook.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nonempty.url = "github:LitFill/nel-kk";
  };

  outputs = { self, nixpkgs, flake-utils, nonempty }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        koka = pkgs.koka;
        lib = nonempty.kokaLibraries.${system}.nonempty;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ koka nonempty.packages.${system}.nonEmptyLib ];
          shellHook = ''
            export KOKA_OPTIONS="--include=${lib.includePath}"
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "my-app";
          version = "0.1.0";
          src = pkgs.lib.cleanSource self;

          nativeBuildInputs = [ koka ];
          buildInputs = [ nonempty.packages.${system}.nonEmptyLib ];

          buildPhase = ''
            koka -o my-app --include="${lib.includePath}" --builddir="$PWD/build" src/main.kk
          '';

          installPhase = ''
            mkdir -p "$out/bin"
            cp my-app "$out/bin/"
          '';
        };
      });
}
```

The `buildInputs` entry is not strictly required for compilation, because the
library source is consumed rather than linked. It is retained so that the
library is present in the build environment and to keep the dependency declared
in one place.

> [!WARNING]
> `src = pkgs.lib.cleanSource self` copies only files tracked by Git. A new
> `src/` directory or an uncommitted `flake.nix` produces a derivation that
> builds and then fails with `could not find: src/main.kk`. Stage new source
> files before building, or use `pkgs.lib.cleanSourceWith` with an explicit
> filter.

`src/main.kk`:

```koka
module main

import nonempty

fun main()
  val ne = 11 <:: 12 <:: single(13)
  ne.println()
  ne.map(_ * 10).println
  "Hello, Koka!"
```

Expected output:

```text
Nonempty(head=11, tail=[12,13])
Nonempty(head=110, tail=[120,130])
Hello, Koka!
```

### Editor and LSP configuration

The Koka language server reads `koka.json` from the project root. The compiler
does not read this file, so it must be written in addition to `KOKA_OPTIONS`,
not instead of it.

```json
{ "include_dirs": ["/nix/store/.../share/koka/3.2.9"] }
```

Generate it from the same shell hook that sets `KOKA_OPTIONS`:

```nix
shellHook = ''
  export KOKA_OPTIONS="--include=${lib.includePath}"
  printf '{"include_dirs":["%s"]}\n' "${lib.includePath}" > "$PWD/koka.json"
'';
```

Add `koka.json` to `.gitignore`; the content contains absolute store paths that
differ per machine.

## Building the library

```bash
nix build .#nonEmptyLib
```

Outputs:

```text
result/share/koka/3.2.9/nonempty.kk      -- source module
result/lib/koka/3.2.9/nonempty/          -- generated .c, .h, .o
```

The build invokes `koka -l --target=c`. The install phase locates the generated
files with `find` rather than hardcoding a path, because the internal build
directory layout is not stable across Koka versions. A `|| true` guard around
that `find` is deliberately absent: a silent miss would otherwise produce a
library that installs successfully and fails only at consumer link time.
