# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../common/prelude
      ../../common/develop
      ../../common/daily
      ../../common/service
    ];

  owner = "zyz";
  profileName = "mond";

  ### Bootloader ###
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  services.vscode-server.enable = true;

  services.dae.enable = true;
  services.dae.configFile = "/home/zyz/nixos-config/profiles/mond/mond.dae";


  services.create_ap.enable = true;
  services.create_ap.settings = {
    INTERNET_IFACE = "wlp1s0";
    ssid = "mond";
    password = "mondmond";
    interface = "wlp1s0";
  };


  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
        PasswordAuthentication = true;
        AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
        UseDns = false;
        X11Forwarding = false;
        PermitRootLogin = "prohibit-password"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
      };
  };

  environment.systemPackages = with pkgs; [
    dae # proxy
  #bitwarden-cli # passwd mgmt
  #jellycli # media host
  #sonarr # auto bttorrent download
  ];
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
