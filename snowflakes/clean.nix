# Snowflake: clean
# Lightweight — shell, git, starship. No editor, no rust, no explore.
# Use for quick tasks, CI-like environments, or minimal WSL instances.
{ config, lib, pkgs, fenix, ... }:

{
  imports = [
    ../home/shell.nix
    ../home/git.nix
    ../home/starship.nix
  ];

  home.username      = "eyu";
  home.homeDirectory = "/home/eyu";
  home.stateVersion  = "25.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    bat eza fd ripgrep jq curl wget btop
  ];
}
