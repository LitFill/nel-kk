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
        kokaVersion = "3.2.9";

        # Build the non-empty library
        nonEmptyLib = pkgs.stdenv.mkDerivation {
          pname = "koka-non-empty";
          version = "0.1.0";

          src = self;

          nativeBuildInputs = [
            koka
            pkgs.makeWrapper
          ];

          buildPhase = ''
            # Set up koka environment
            export KOKA_PATH="${koka}/share/koka/${kokaVersion}"

            # Build the library with --target=c to generate library files
            ${koka}/bin/koka -l --target=c \
              --builddir="''${PWD}/.koka-build" \
              --output=nonempty \
              nonempty/nonempty.kk
          '';

          installPhase = ''
            mkdir -p $out/share/koka/${kokaVersion}
            mkdir -p $out/lib/koka/${kokaVersion}/nonempty

            # Copy source .kk file to share (at top level for module resolution)
            cp nonempty/nonempty.kk $out/share/koka/${kokaVersion}/nonempty.kk

            # Copy .c, .h, .o files (implementation) - these go to lib
            cp -r .koka-build/v${kokaVersion}/*/nonempty*.c $out/lib/koka/${kokaVersion}/nonempty/ 2>/dev/null || true
            cp -r .koka-build/v${kokaVersion}/*/nonempty*.h $out/lib/koka/${kokaVersion}/nonempty/ 2>/dev/null || true
            cp -r .koka-build/v${kokaVersion}/*/nonempty*.o $out/lib/koka/${kokaVersion}/nonempty/ 2>/dev/null || true
          '';
        };

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            koka
            nonEmptyLib
          ];
          shellHook = ''
            export KOKA_PATH="${koka}/share/koka/${kokaVersion}:${nonEmptyLib}/share/koka/${kokaVersion}"
            echo "Koka non-empty library available at: ${nonEmptyLib}"
            echo "Use -i ${nonEmptyLib}/share/koka/${kokaVersion} to include nonempty in your project"
          '';
        };

        packages.nonEmptyLib = nonEmptyLib;

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
