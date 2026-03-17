{ config, lib, ... }:

let
  cfg = config.services.tailscaleAutoConnect;
in
{
  options.services.tailscaleAutoConnect = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = lib.mkDefault true;

    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall (lib.mkAfter [ 41641 ]);
  };
}
