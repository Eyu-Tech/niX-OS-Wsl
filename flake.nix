{
  description = "EtheReoN — NixOS-WSL instance with Podman + Rust (declarative, reproducible)";

  inputs = {
    # nixpkgs unstable — pin to "nixos-24.11" or similar if needed
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # The module that makes NixOS run under WSL2
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager — user-scoped config (dotfiles, shell tools, prompts)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # fenix — Rust toolchains (stable/beta/nightly) + matching rust-analyzer
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, home-manager, fenix, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.ethereon = nixpkgs.lib.nixosSystem {
        inherit system;
        # Pass fenix as argument to modules (needed in home.nix)
        specialArgs = { inherit fenix; };
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix

          # Make fenix overlay available
          { nixpkgs.overlays = [ fenix.overlays.default ]; }

          # Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit fenix; };
            home-manager.users.eyu = import ./home.nix;
          }
        ];
      };
    };
}
