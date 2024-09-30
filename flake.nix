{
  description = "Ekstasis's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
        mond = nixpkgs.lib.nixosSystem { # N100
          system = "x86_64-linux";
          modules = [
            ./profiles/mond/configuration.nix
          ];
        };
        Sonne = nixpkgs.lib.nixosSystem { # Cloud Server
          system = "x86_64-linux";
          modules = [
            ./profiles/sonne/configuration.nix
          ];
        };
    };
  };
}