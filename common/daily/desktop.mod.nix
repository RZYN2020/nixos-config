{ config, pkgs, lib, ... }: 
{

    # 字体配置
    fonts = {
      fontconfig.enable = true;
      enableFontDir = true;
      enableGhostscriptFonts = true;
      fonts = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        wqy_microhei
        wqy_zenhei
      ];
    };


  environment.systemPackages = with pkgs; [
    microsoft-edge-stable
    clash-verge-rev
    vscode
  ];
}