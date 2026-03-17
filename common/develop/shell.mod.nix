{ config, pkgs, lib, ... }: 
{
  config = lib.mkIf config.develop.enable {
    environment.systemPackages = with pkgs; [
      expect # expect, autoexpect
      git
      curl
      wget
      tmux
      htop
      neovim
      ripgrep
      fd
      unzip
      zip
      cloudflared
      cloudflared-legacy
    ];
  };
}
