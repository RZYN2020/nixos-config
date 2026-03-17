{ config, pkgs, lib, ... }: 
{
  imports = [
  ];

  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      mysql84
    ];
  };
}
