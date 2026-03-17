{ config, pkgs, lib, ... }:

let
  cfg = config.services.cloudflaredTunnel;
in
{
  options.services.cloudflaredTunnel = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cloudflared;
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/cloudflared/config.yml";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel (cloudflared)";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      unitConfig.ConditionPathExists =
        [ cfg.configFile ] ++ lib.optionals (cfg.credentialsFile != null) [ cfg.credentialsFile ];
      serviceConfig = {
        User = cfg.user;
        ExecStart = lib.mkForce (
          toString cfg.package + "/bin/cloudflared --config " +
          toString cfg.configFile +
          " tunnel run" +
          (if cfg.extraArgs == [] then "" else " " + lib.escapeShellArgs cfg.extraArgs)
        );
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
