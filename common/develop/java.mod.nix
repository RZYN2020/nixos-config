{ config, pkgs, lib, ... }: 
{
  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      openjdk maven #adoptopenjdk-bin
    ];
    programs.java.enable = true;
  };
}
