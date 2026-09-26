{
  description = "Non empty list library for Koka";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        koka = pkgs.koka;

        # Derive dari paket koka itu sendiri, jangan hardcode angka versi
        # supaya tidak drift saat nixpkgs update koka.
        kokaVersion = koka.version;

        # Build the non-empty library
        nonEmptyLib = pkgs.stdenv.mkDerivation {
          pname = "koka-non-empty";
          version = "0.1.2";

          src = pkgs.lib.cleanSource self;

          nativeBuildInputs = [
            koka
          ];

          buildPhase = ''
            runHook preBuild

            # Set up koka environment
            export KOKA_PATH="${koka}/share/koka/${kokaVersion}"

            # Build the library with --target=c to generate library files
            ${koka}/bin/koka -l --target=c \
              --builddir="$PWD/.koka-build" \
              --output=nonempty \
              nonempty/nonempty.kk

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/koka/${kokaVersion}
            mkdir -p $out/lib/koka/${kokaVersion}/nonempty

            # Copy source .kk file to share (at top level for module resolution)
            cp nonempty/nonempty.kk $out/share/koka/${kokaVersion}/nonempty.kk

            # Cari file hasil generate koka lewat `find` alih-alih menebak
            # kedalaman/nama persis direktori build internalnya (rawan
            # berubah antar versi koka, dan kalau ditebak salah sebelumnya
            # error-nya ditelan diam-diam oleh `|| true`).
            c_files=$(find .koka-build -type f -name 'nonempty*.c')
            h_files=$(find .koka-build -type f -name 'nonempty*.h')
            o_files=$(find .koka-build -type f -name 'nonempty*.o')

            if [ -z "$c_files" ]; then
              echo "ERROR: tidak menemukan nonempty*.c di bawah .koka-build" >&2
              echo "Isi .koka-build saat ini:" >&2
              find .koka-build >&2
              exit 1
            fi

            cp $c_files $out/lib/koka/${kokaVersion}/nonempty/
            [ -n "$h_files" ] && cp $h_files $out/lib/koka/${kokaVersion}/nonempty/
            [ -n "$o_files" ] && cp $o_files $out/lib/koka/${kokaVersion}/nonempty/

            runHook postInstall
          '';
        };

        # Test suite, built against the library produced above so that a
        # regression cannot pass by accident.
        testLib = pkgs.stdenv.mkDerivation {
          pname = "nonempty-test";
          version = nonEmptyLib.version;

          src = pkgs.lib.cleanSource self;

          nativeBuildInputs = [ koka ];

          buildPhase = ''
            runHook preBuild
            koka -o nonempty-test \
              --include="${nonEmptyLib}/share/koka/${kokaVersion}" \
              --builddir="$PWD/.koka-build" \
              nonempty/test.kk
            runHook postBuild
          '';

          doCheck = true;
          checkPhase = ''
            runHook preCheck
            ./nonempty-test
            runHook postCheck
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/bin"
            cp nonempty-test "$out/bin/"
            runHook postInstall
          '';
        };

        # HTML API reference, produced by the Koka compiler's `--html` backend
        # via scripts/build-docs.sh. That script is the single source of truth
        # for the pipeline: it repairs the anchors the compiler splits across
        # the API and source pages, and it fails the build if any internal
        # link does not resolve.
        docs = pkgs.stdenv.mkDerivation {
          pname = "koka-non-empty-docs";
          version = nonEmptyLib.version;

          src = pkgs.lib.cleanSource self;

          nativeBuildInputs = [
            koka
            pkgs.gnugrep
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            # Invoked through bash explicitly: the build sandbox has no
            # /usr/bin/env for the script's shebang to resolve.
            KOKA=${koka}/bin/koka bash scripts/build-docs.sh docs

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -r docs/. "$out/"
            runHook postInstall
          '';

          # Regenerating the reference is the common case, and it needs the
          # sources, so build it here rather than on a remote builder.
          preferLocalBuild = true;
        };
      in
      {
        # The dev shell builds the library and exposes it on the module search
        # path. `KOKA_OPTIONS` is used rather than `KOKA_PATH`, because the
        # compiler does not read `KOKA_PATH` when resolving user modules.
        devShells.default = pkgs.mkShell {
          packages = [
            koka
            nonEmptyLib
            # scripts/build-docs.sh uses GNU grep; the stdenv does not always
            # provide it.
            pkgs.gnugrep
          ];

          shellHook = ''
            export KOKA_OPTIONS="--include=${nonEmptyLib}/share/koka/${kokaVersion}"
            printf '{"include_dirs":["%s"]}\n' \
              "${nonEmptyLib}/share/koka/${kokaVersion}" > "$PWD/koka.json"
            echo "nonempty ${nonEmptyLib.version} on module path; run: koka -o out nonempty/test.kk"
            echo "docs: scripts/build-docs.sh docs"
          '';
        };

        checks.tests = testLib;
        checks.default = testLib;

        packages.nonEmptyLib = nonEmptyLib;
        packages.default = nonEmptyLib;

        packages.docs = docs;

        # The docs derivation verifies every internal link it emits, so a
        # broken reference fails `nix flake check` like any other regression.
        checks.docs = docs;

        # Library info for consuming flakes. `version` is the Koka version,
        # which keys the share/ and lib/ paths; `libVersion` is this library's
        # own version. Consumers must not hardcode either.
        kokaLibraries.nonempty = {
          path = nonEmptyLib;
          includePath = "${nonEmptyLib}/share/koka/${kokaVersion}";
          libPath = "${nonEmptyLib}/lib/koka/${kokaVersion}";
          version = kokaVersion;
          libVersion = nonEmptyLib.version;
        };
      }
    );
}
