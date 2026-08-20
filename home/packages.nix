{ config, lib, pkgs, fenix, ... }:

let
  rustToolchain = fenix.packages.${pkgs.stdenv.hostPlatform.system}.stable.withComponents [
    "cargo" "clippy" "rust-src" "rustc" "rustfmt"
  ];
  rustAnalyzer = fenix.packages.${pkgs.stdenv.hostPlatform.system}.rust-analyzer;
in
{
  home.packages = with pkgs; [
    # Rust toolchain (fenix)
    rustToolchain
    rustAnalyzer
    cargo-watch
    cargo-edit
    cargo-nextest
    bacon
    mold
    sccache
    cargo-flamegraph
    hyperfine
    cargo-expand
    cargo-audit
    cargo-deny
    cargo-outdated
    clang

    # Terminal workspace
    zellij
    broot
    just
    watchexec
    tealdeer

    # Search & navigation
    fd
    ripgrep
    yazi

    # Git TUIs
    # git-scope  # not in nixpkgs — install manually if needed
    gitui
    tig

    # Pretty & useful
    bat
    eza
    dust
    duf
    procs
    btop
    jq
    tree
    curl
    wget
  ];

  home.file.".cargo/config.toml".text = ''
    [build]
    rustc-wrapper = "${pkgs.sccache}/bin/sccache"

    [target.x86_64-unknown-linux-gnu]
    linker    = "${pkgs.clang}/bin/clang"
    rustflags = ["-C", "link-arg=-fuse-ld=${pkgs.mold}/bin/mold"]
  '';
}
