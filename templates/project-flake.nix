# EtheReoN project template — copy to your project root as flake.nix
#
# Usage:
#   cp /path/to/nixos-wsl/templates/project-flake.nix ./flake.nix
#   # Edit description and REPO-NAME below
#   nix develop
#
# Or via cargo-generate (if a template repo is set up):
#   cargo generate --git <template-repo> --name my-project
{
  description = "EtheReoN — <REPO-NAME> dev shell (isolated, reproducible)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, fenix, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ] (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        rustToolchain = fenix.packages.${system}.stable.withComponents [
          "cargo" "clippy" "rust-src" "rustc" "rustfmt"
        ];
        rustAnalyzer = fenix.packages.${system}.rust-analyzer;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rustToolchain
            rustAnalyzer
            pkgs.cargo-watch
            pkgs.cargo-nextest
            pkgs.cargo-edit
            pkgs.mold
            pkgs.sccache
            pkgs.clang
            pkgs.just

            # Project-specific tools — add/remove as needed:
            # pkgs.sqlx-cli
            # pkgs.protobuf
            # pkgs.openssl
          ];

          shellHook = ''
            export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="${pkgs.clang}/bin/clang"
            export RUSTFLAGS="-C link-arg=-fuse-ld=${pkgs.mold}/bin/mold"
            export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
            echo "=== <REPO-NAME> dev shell (nixos-unstable, fenix stable) ==="
            echo "    just <recipe>   — run project tasks"
            echo "    cargo nextest   — run tests"
          '';
        };
      }
    );
}
