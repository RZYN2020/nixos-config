{ config, pkgs, lib, ... }: 
{
  #Ref: https://nixos.wiki/wiki/Node.js

  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      nodejs
    ];
  };
}
