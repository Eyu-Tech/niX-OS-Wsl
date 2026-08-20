# Explore: Claude CLI integration
#
# Makes the claude CLI available inside the WSL instance so both you and
# other fäden (agents) can call it directly from the shell.
#
# Usage after rebuild:
#   claude --version
#   claude "explain this Rust error: ..."
#   claude --print "review my flake.nix" < flake.nix
#
# Fäden (other Claude Code sessions) can invoke it via:
#   wsl -d NixOS -- claude --print "..."
#
# Node is required — claude CLI is distributed as an npm package.
# If pkgs.claude-code is not yet in nixpkgs-unstable, the fallback
# fetches it via pkgs.nodePackages (see comment below).
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Primary: packaged in nixpkgs as of 2025
    # If evaluation fails with "attribute 'claude-code' missing",
    # comment this out and use the nodePackages fallback below.
    claude-code

    # Fallback (uncomment if needed):
    # (pkgs.nodePackages.claude-code or (pkgs.runCommand "claude-code" {} ''
    #   echo "claude-code not found in nixpkgs — install manually via npm" && exit 1
    # ''))
  ];
}
