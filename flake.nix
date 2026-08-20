{
  description = "EtheReoN — NixOS-WSL instance (declarative, reproducible, multi-snowflake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # release-26.05 — closest stable HM release to nixpkgs-unstable (26.11).
    # master uses lib.genAttrs' not yet in nixpkgs-unstable (as of 2026-06).
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, home-manager, fenix, ... }:
    let
      system = "x86_64-linux";

      # Builds a NixOS system wired to a given snowflake home module.
      mkSystem = snowflakeModule: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit fenix; };
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
          { nixpkgs.overlays = [ fenix.overlays.default ]; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs    = true;
            home-manager.useUserPackages  = true;
            home-manager.extraSpecialArgs = { inherit fenix; };
            home-manager.users.eyu        = snowflakeModule;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        # Full workstation — editor, rust, all tools.
        ethereon = mkSystem (import ./snowflakes/full.nix);

        # Lightweight shell — git + nushell + starship, no editor, no rust.
        ethereon-clean = mkSystem (import ./snowflakes/clean.nix);

        # Project scaffold — shows templates/ workflow, installs project-bootstrap tools.
        ethereon-proj = mkSystem (import ./snowflakes/proj.nix);
      };
    };
}
