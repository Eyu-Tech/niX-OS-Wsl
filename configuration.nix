{ config, lib, pkgs, ... }:

{
  # ─── WSL basics ────────────────────────────────────────────────────
  wsl = {
    enable = true;
    defaultUser = "eyu";
    # Forward Windows PATH into WSL (e.g. to use `code.exe`).
    # Set to false for a clean separation.
    interop.includePath = true;
    # `wsl --shutdown` behaves more cleanly with native systemd:
    wslConf.boot.systemd = true;
  };

  # ─── Flakes & modern Nix CLI ───────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Automatically clean up old generations
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # ─── Podman instead of Docker ──────────────────────────────────────
  virtualisation.podman = {
    enable = true;
    # Creates a `docker` alias pointing to podman → `docker run ...` works.
    dockerCompat = true;
    # DNS between containers in a network (important for podman-compose)
    defaultNetwork.settings.dns_enabled = true;
    # Clean up unused containers/images
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # ─── User ──────────────────────────────────────────────────────────
  users.users.eyu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];  # sudo
  };

  # ─── Gitea (declarative via Podman, root-managed systemd service) ──
  # NixOS starts the container as a root systemd unit at boot.
  # Data lives in a Podman-managed named volume `gitea-data`.
  #
  # Reachable after rebuild:
  #   Web : http://localhost:3000
  #   SSH : ssh://git@localhost:2222   (rootless ⇒ ports ≥ 1024)
  virtualisation.oci-containers = {
    backend = "podman";
    containers.gitea = {
      image = "docker.io/gitea/gitea:1.22";
      autoStart = true;
      ports = [
        "3000:3000"   # Web UI
        "2222:22"     # Git over SSH
      ];
      volumes = [
        "gitea-data:/data"
      ];
      environment = {
        USER_UID = "1000";
        USER_GID = "1000";
        GITEA__server__ROOT_URL = "http://localhost:3000/";
        GITEA__server__SSH_PORT = "2222";
        GITEA__server__DOMAIN  = "localhost";
      };
    };
  };

  # ─── System packages (machine-level, not user) ─────────────────────
  # User tools (git, neovim, fzf, yazi, lazygit, starship …) live
  # intentionally in home.nix. Only what truly belongs system-wide here.
  environment.systemPackages = with pkgs; [
    podman-compose   # docker-compose equivalent for Podman
    dive             # inspect container image layers
  ];

  # ─── Miscellaneous ─────────────────────────────────────────────────
  # Allow unfree packages (e.g. certain tools). Remove if not needed.
  nixpkgs.config.allowUnfree = true;

  # Do NOT change this after installation (controls state migrations).
  system.stateVersion = "24.11";
}
