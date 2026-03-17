{ lib, ... }:
{
  options.develop.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
}
