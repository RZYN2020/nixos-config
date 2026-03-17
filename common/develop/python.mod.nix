{ config, pkgs, lib, ... }: 
{
  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      python3
    ];
  };
}
