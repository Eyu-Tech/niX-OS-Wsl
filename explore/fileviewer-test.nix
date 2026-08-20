# Explore: file viewer candidates
#
# All three installed simultaneously so you can test them side-by-side in a
# real WSL session. Pick a winner, drop the others from the next snowflake.
#
# Candidates:
#   yazi  — Rust, image preview, async, plugin system
#   broot — fuzzy tree navigation, custom verbs, fast on large dirs
#   nnn   — minimal, keyboard-driven, plugin ecosystem
#
# Test aliases:
#   fy   → yazi
#   fb   → broot
#   fn   → nnn
#
# Evaluation criteria (run each, compare):
#   - startup time:    time fy / time fb / time fn
#   - image preview:   works in WSL?
#   - large dir perf:  open /nix/store
#   - keybindings:     feel / learning curve
#   - git integration: shows dirty files?
{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [ yazi broot nnn ];

  programs.nushell.extraConfig = ''
    alias fy = yazi
    alias fb = broot
    alias fn = nnn
  '';

  programs.bash.shellAliases = { fy = "yazi"; fb = "broot"; fn = "nnn"; };
  programs.zsh.shellAliases  = { fy = "yazi"; fb = "broot"; fn = "nnn"; };
  programs.fish.shellAliases = { fy = "yazi"; fb = "broot"; fn = "nnn"; };
}
