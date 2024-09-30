{ config, pkgs, lib, ... }: 
{
  imports = [
  ];

  config = {
    environment.systemPackages = with pkgs; [
      mysql84
    ];
  };
}
