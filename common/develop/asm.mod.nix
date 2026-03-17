{ config, pkgs, lib, ... }: 
{
  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      radare2 # radare2
      pax-utils # dumpelf, lddtree, symtree, scanelf, pspax, scanmacho
    ];
  };
}
