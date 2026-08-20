{ config, lib, pkgs, fenix, ... }:

{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./starship.nix
    ./editor.nix
  ];

  home.username      = "eyu";
  home.homeDirectory = "/home/eyu";
  home.stateVersion  = "25.05";

  # Suppress version mismatch warning (HM 25.05 / 26.05 + nixpkgs 26.11).
  # Remove once home-manager lock is updated to release-26.05.
  home.enableNixpkgsReleaseCheck = false;

  programs.home-manager.enable = true;

  # Ensure HM profile bin is in PATH for all shells including nushell.
  home.sessionPath = [
    "$HOME/.nix-profile/bin"
    "/etc/profiles/per-user/${config.home.username}/bin"
    "/run/current-system/sw/bin"
  ];
}
