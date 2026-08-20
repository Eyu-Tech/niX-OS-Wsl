{ config, lib, pkgs, ... }:

let
  sharedAliases = {
    ls  = "eza --icons --group-directories-first";
    ll  = "eza -la --icons --group-directories-first";
    cat = "bat";
    lg  = "lazygit";
    # gs  = "git-scope";  # not in nixpkgs
    gu  = "gitui";
    y   = "yazi";
    cw  = "cargo watch -x check";
    cn  = "cargo nextest run";
  };
in
{
  # fzf — fuzzy finder
  programs.fzf = {
    enable                 = true;
    enableBashIntegration  = true;
    enableZshIntegration   = true;
    enableFishIntegration  = true;
  };

  # zoxide — smart cd
  programs.zoxide = {
    enable                 = true;
    enableBashIntegration  = true;
    enableZshIntegration   = true;
    enableFishIntegration  = true;
    enableNushellIntegration = true;
    options                = [ "--cmd cd" ];
  };

  # Nushell — primary shell
  programs.nushell = {
    enable = true;
    extraConfig = ''
      $env.config = {
        show_banner: false
        edit_mode: vi
        keybindings: []
      }

      # Aliases
      alias ls  = eza --icons --group-directories-first
      alias ll  = eza -la --icons --group-directories-first
      alias cat = bat
      alias lg  = lazygit
      # alias gs  = git-scope  # not in nixpkgs
      alias gu  = gitui
      alias y   = yazi
      alias cw  = cargo watch -x check
      alias cn  = cargo nextest run
    '';
    environmentVariables = {
      EDITOR = "nvim";
    };
  };

  # Bash fallback
  programs.bash = {
    enable       = true;
    shellAliases = sharedAliases;
  };

  # Zsh fallback
  programs.zsh = {
    enable                   = true;
    enableCompletion         = true;
    autosuggestion.enable    = true;
    syntaxHighlighting.enable = true;
    shellAliases             = sharedAliases;
  };

  # Fish fallback
  programs.fish = {
    enable       = true;
    shellAliases = sharedAliases;
  };
}
