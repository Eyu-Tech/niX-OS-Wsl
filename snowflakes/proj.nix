# Snowflake: proj
# Project-bootstrap environment.
#
# Purpose of templates/:
#   The templates/project-flake.nix file is the canonical starting point for
#   new Rust/Nix projects in the EtheReoN ecosystem. This snowflake installs
#   the tools needed to USE those templates and demonstrates the workflow:
#
#     cp templates/project-flake.nix ~/my-project/flake.nix
#     cd ~/my-project && nix develop
#
#   cargo-generate can scaffold the project skeleton; just runs the justfile;
#   the fenix toolchain declared in the template matches what this snowflake
#   provides — same versions, reproducible across machines.
{ config, lib, pkgs, fenix, ... }:

{
  imports = [
    ../home/default.nix
  ];

  home.packages = with pkgs; [
    cargo-generate   # `cargo generate` — scaffold from git templates
    just             # run justfile recipes defined in project templates
    tokei            # count lines of code across a new project
    hyperfine        # benchmark new project binaries
  ];
}
