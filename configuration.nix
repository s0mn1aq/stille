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
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

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

  #|--------|
  #| locale |
  #|--------|
  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";
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
    pam.services.swaylock = {};
  };

  #|----------------|
  #| identification |
  #|----------------|
  users.users.somniaq = {
    isNormalUser = true;
    description = "king";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    hashedPassword = "$y$j9T$MxvfAZ4B1nH2CNazLHi6q1$KGv.NOmIDCOKzdDUb9bfNe7ZvXzIcxX/tT8nR3V5Jg/";
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
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 352800 384000 ];
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
        };
      };
    };
  };

  #|----------|
  #| software |
  #|----------|
  programs.dconf.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.somniaq = { pkgs, ... }: {
      home.stateVersion = "26.05";
      wayland.windowManager.sway = {
        enable = true;
        package = pkgs.swayfx;
        extraOptions = [ "--unsupported-gpu" ];
      };
      programs = {
        # graphic shell
        fuzzel.enable = true;
        swaylock.enable = true;
        # application
        mpv.enable = true;
        imv.enable = true;
        # utility
        alacritty.enable = true;
        nushell.enable = true;
        zellij.enable = true;
        helix.enable = true;
        yazi.enable = true;
        eza.enable = true;
        bat.enable = true;
        zoxide.enable = true;
        git.enable = true;
        gitui.enable = true;
        skim.enable = true;
        fd.enable = true;
        ripgrep.enable = true;
        btop.enable = true;
        fastfetch.enable = true;
      };
      services = {
        mullvad-vpn.enable = true;
        zerotierone.enable = true;
        mako.enable = true;
        swayidle.enable = true;
      };
      home.packages = with pkgs; [
        # graphic shell
        yambar
        swaybg
        grim
        slurp
        # application
        _64gram-desktop
        zen-browser
        mpd
        rqbit
        rmpc
        mupdf
        # utility
        playerctl
        brightnessctl
        pciutils
        usbutils
        ouch
        par2cmdline-turbo
        rage
        ffmpeg
        cpufetch
        gpufetch
        onefetch
        doas-sudo-shim
        wl-clipboard
        wlr-randr
      ];
    };
  };

  #|--------|
  #| script |
  #|--------|
  programs.bash.interactiveShellInit = ''
    tg-pack() {
      [ -n "$1" ] || return 1
      local s="''${1%/}" p="''${1%/}.tar.age.part"
      ( set -o pipefail; tar -cf - "$s" | age -p -o - | split -b 1920MB -d --numeric-suffixes=1 -a 2 - "$p" ) || return 1
      local a=("''$p"*)
      if [ ''${#a[@]} -le 9 ]; then
        for f in "''${a[@]}"; do [ -f "$f" ] && mv "$f" "''${f%part0*}part''${f##*part0}"; done
        a=("''$p"*)
      fi
      local b=0
      for f in "''${a[@]}"; do b=$((b + $(stat -c%s "$f"))); done
      local k=$(( (b / 10 + 1919999999) / 1920000000 ))
      [ "$k" -lt 1 ] && k=1
      par2 c -r10 -n"$k" "$s.par2" "''${a[@]}"
    }
    tg-unpack() {
      [ -n "$1" ] || return 1
      local b="''${1%/}"
      b="''${b%.par2}"
      b="''${b%.tar.age.part*}"
      ls "$b.tar.age.part"* >/dev/null 2>&1 || return 1
      par2 r "$b.par2" && cat "$b.tar.age.part"* | age -d | tar -xf -
    }
    complete -d tg-pack
    complete -f -d tg-unpack
  '';

  #|-----|
  #| nix |
  #|-----|
  nixpkgs.config.allowUnfree = true;
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
