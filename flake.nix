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
          version = "0.1.1";

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

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            koka
            # nonEmptyLib
          ];
          # shellHook = ''
          #   export KOKA_PATH="${koka}/share/koka/${kokaVersion}:${nonEmptyLib}/share/koka/${kokaVersion}"
          #   echo "Koka non-empty library available at: ${nonEmptyLib}"
          #   echo "Use -i ${nonEmptyLib}/share/koka/${kokaVersion} to include nonempty in your project"
          # '';
        };

        packages.nonEmptyLib = nonEmptyLib;
        packages.default = nonEmptyLib;

        # Provide library info for other flakes to consume
        kokaLibraries.nonempty = {
          path = nonEmptyLib;
          includePath = "${nonEmptyLib}/share/koka/${kokaVersion}";
          libPath = "${nonEmptyLib}/lib/koka/${kokaVersion}";
          version = kokaVersion;
        };
      }
    );
}
