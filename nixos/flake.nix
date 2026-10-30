{
  description = "Peng's NixOS + niri Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs_unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs_unstable, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";

    pkgs_unstable = import nixpkgs_unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations."nixos" = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs pkgs_unstable; };

      modules = [
        ./system/hardware-configuration.nix
        ./system/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
