{
  description = "Ekstasis's NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    daeuniverse.url = "github:daeuniverse/flake.nix";
    sops-nix.url = "github:Mic92/sops-nix";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, vscode-server, daeuniverse, sops-nix, claude-code, ... }@inputs: {
    nixosConfigurations = {
      mond = nixpkgs.lib.nixosSystem { # N100
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.overlays = [ claude-code.overlays.default ];
          }
          daeuniverse.nixosModules.dae
          daeuniverse.nixosModules.daed
          vscode-server.nixosModules.default
          sops-nix.nixosModules.sops
          ./profiles/mond/configuration.nix
        ];
      };
      sonne = nixpkgs.lib.nixosSystem { # Cloud Server
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.overlays = [ claude-code.overlays.default ];
          }
          sops-nix.nixosModules.sops
          ./profiles/sonne/configuration.nix
        ];
      };
    };
  };
}
