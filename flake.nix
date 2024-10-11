{
  description = "Ekstasis's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, vscode-server,... }@inputs: {
    nixosConfigurations = {
        mond = nixpkgs.lib.nixosSystem { # N100
          system = "x86_64-linux";
          modules = [
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