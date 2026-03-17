{ config, pkgs, lib, ... }:

let
  cfg = config.develop.ai;
in
{
  options.develop.ai = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    claudeCode = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Claude Code CLI integration (requires secrets.anthropic.enable)";
      };
      
      runtime = lib.mkOption {
        type = lib.types.enum [ "native" "node" "bun" ];
        default = "native";
        description = "Which claude-code runtime to use from sadjow/claude-code-nix overlay";
      };
    };
  };

  config = lib.mkIf (config.develop.enable && cfg.enable) {
    environment.systemPackages =
      (lib.optionals (pkgs ? nodejs) [ pkgs.nodejs ])
      ++ (lib.optionals (pkgs ? uv) [ pkgs.uv ])
      ++ (lib.optionals (pkgs ? pipx) [ pkgs.pipx ])
      ++ (lib.optionals (pkgs ? gh) [ pkgs.gh ])
      ++ (lib.optionals (cfg.claudeCode.enable && config.secrets.anthropic.enable) [
        (pkgs.writeShellScriptBin "claude" ''
          set -euo pipefail

          keyPath="${config.sops.secrets.${config.secrets.anthropic.primarySecretName}.path}"

          export ANTHROPIC_API_KEY="$(cat "$keyPath")"
          
          # Call the actual claude binary provided by the overlay
          ${if cfg.claudeCode.runtime == "native" then
            "exec ${pkgs.claude-code}/bin/claude \"$@\""
          else if cfg.claudeCode.runtime == "node" then
            "exec ${pkgs.claude-code-node}/bin/claude-node \"$@\""
          else
            "exec ${pkgs.claude-code-bun}/bin/claude-bun \"$@\""}
        '')
      ]);
  };
}
