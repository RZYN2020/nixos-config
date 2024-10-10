{ config, pkgs, lib, ... }: 
{
  environment.systemPackages = with pkgs; [
    dae # proxy
  #bitwarden-cli # passwd mgmt
  #jellycli # media host
  #sonarr # auto bttorrent download
  ];
}
