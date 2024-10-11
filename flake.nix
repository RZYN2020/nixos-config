{
  description = "Ekstasis's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    daeuniverse.url = "github:daeuniverse/flake.nix";
  };

  outputs = { self, nixpkgs, vscode-server, daeuniverse, ... }@inputs: {
    nixosConfigurations = {
        mond = nixpkgs.lib.nixosSystem { # N100
          system = "x86_64-linux";
          specialArgs = { inherit inputs;};
          modules = [
            daeuniverse.nixosModules.dae
            daeuniverse.nixosModules.daed
            vscode-server.nixosModules.default
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