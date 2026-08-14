{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];
  system.stateVersion = "26.05";

  #|------|
  #| core |
  #|------|
  boot = {
    kernelPackages = pkgs.linuxPackages_zen;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
    kernelParams = [
      "quiet"
      "loglevel=3"
      "splash"
      "nowatchdog"
      "mitigations=off"
    ];
    kernelModules = [ "kvm-intel" ];
    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.printk" = "3 3 3 3";
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  #|----------|
  #| hardware |
  #|----------|
  hardware = {
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      open = true;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  powerManagement.cpuFreqGovernor = "performance";

  #|---------|
  #| network |
  #|---------|
  networking = {
    hostName = "field";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
  services.zerotierone = {
    enable = true;
  };

  #|--------|
  #| locale |
  #|--------|
  time.timeZone = "Europe/Minsk";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };
  services.xserver.xkb = {
    layout = "us";
  };
  console.useXkbConfig = true;

  #|----------|
  #| security |
  #|----------|
  security = {
    rtkit.enable = true;
    apparmor.enable = true;
    sudo.enable = false;
    doas = {
      enable = true;
      extraRules = [{
        users = [ "somniaq" ];
        keepEnv = true;
        persist = true;
      }];
    };
  };

  #|----------------|
  #| identification |
  #|----------------|
  users.users.somniaq = {
    isNormalUser = true;
    description = "queen of the meadow";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    hashedPassword = "$y$j9T$OfVv5WBZ9ASk2.38kGt7l/$NGUAMpBq3OApTt9XUz5qru63aqb2xIybBNLe6VL3iE6";
  };

  #|-------|
  #| audio |
  #|-------|
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire = {
      "10-audiophile-clock" = {
        "context.properties" = {
          "default.clock.rate" = 96000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 192000 ];
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 1024;
        };
      };
    };
  };

  #|----------|
  #| software |
  #|----------|
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${inputs.noctalia-greeter.packages.${pkgs.system}.default}/bin/noctalia-greeter";
        user = "greeter";
      };
    };
  };
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };
  users.groups.greeter = {};

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = "kvantum";
  };
  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.system}.default
    labwc
    xwayland
    qt5ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qt6ct
    kdePackages.kvantum
    lxqt.lxqt-policykit
    doas-sudo-shim
    wineWowPackages.waylandFull
    winetricks
    dxvk
    vkd3d
    gamemode
    portproton
    nheko
    coolreader
    featherpad
    krita
    lxqt.lximage-qt
    strawberry
    pavucontrol-qt
    haruna
    obs-studio
    sioyek
    qterminal
    falkon
    pcmanfm-qt
    lxqt.lxqt-archiver
    pciutils
    usbutils
    git
  ];

  #|-----|
  #| nix |
  #|-----|
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      cores = 0;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
