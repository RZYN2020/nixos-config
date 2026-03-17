{ config, pkgs, lib, ... }: 
{
  options = {
    develop.c.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether need c develop environment
      '';
    };
    develop.c.toolchain = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether need c toolchain to build from source code
      '';
    };
    develop.c.debug = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether need c debug tools to debug c programs
      '';
    };
  };

  config = lib.mkIf (config.develop.enable && config.develop.c.enable) {
    environment.systemPackages =
      (lib.optionals config.develop.c.toolchain (with pkgs; [ gcc gnumake ]))
      ++ (lib.optionals config.develop.c.debug (with pkgs; [ gdb ]));
  };
}
