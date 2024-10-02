{ config, pkgs, lib, ... }: 
{




  environment.systemPackages = with pkgs; [
    sftpgo # file server
    dae # proxy
    wastebin # pastbin
    bitwarden-cli # passwd mgmt
    jellycli # media host
    sonarr # auto bttorrent download
  ];
}
