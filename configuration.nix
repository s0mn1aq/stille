{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "field";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    # Add packages here
  ];

  services.openssh.enable = true;

  users.users.root.initialPassword = "changeme";

  system.stateVersion = "26.05";
}