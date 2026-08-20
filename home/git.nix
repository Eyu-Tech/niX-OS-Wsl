{ config, lib, pkgs, ... }:

let
  local = import ../.local/local.nix;
in
{
  programs.git = {
    enable   = true;
    settings = {
      user.name        = local.git.userName;
      user.email       = local.git.userEmail;
      init.defaultBranch = "main";
      pull.rebase        = true;
    };
  };

  programs.delta = {
    enable                = true;
    enableGitIntegration  = true;
  };

  programs.lazygit.enable = true;
}
