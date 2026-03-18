# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../common/prelude
      ../../common/secrets
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

  
  # networking.firewall.allowedTCPPorts = [ 2023 ]; # 22 was opened automatically

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    openFirewall = false;
    settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [ "zyz" ];
        UseDns = false;
        X11Forwarding = false;
        PermitRootLogin = "no";
      };
  };

  services.tailscale.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  services.dae = {
    enable = true;
    configFile = config.sops.secrets.dae-config.path;

    openFirewall = {
      enable = true;
      port = 12345;
    };
  };

  sops.secrets.dae-config = {
    mode = "0400";
    # dae service runs as root usually, so root:root is fine.
    # If dae runs as a specific user, change owner here.
  };

  environment.systemPackages =
    with inputs.daeuniverse.packages.x86_64-linux;
     [ dae pkgs.lshw];
  # environment.systemPackages = with pkgs; [
  #bitwarden-cli # passwd mgmt
#	lshw
  #jellycli # media host
  #sonarr # auto bttorrent download
 #  ];
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
