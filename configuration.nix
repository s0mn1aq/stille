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
    hostName = "stille";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };
  services.mullvad-vpn.enable = true;
  services.zerotierone.enable = true;

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
        users = [ "stummer" ];
        keepEnv = true;
        persist = true;
      }];
    };
    pam.services.swaylock = {};
  };
  environment.systemPackages = with pkgs; [
    doas-sudo-shim
  ];

  #|----------------|
  #| identification |
  #|----------------|
  users.users.stummer = {
    isNormalUser = true;
    description = "der stumme";
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
    users.stummer = { config, pkgs, ... }: {
      home.stateVersion = "26.05";
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
        download = "${config.home.homeDirectory}/download";
        documents = "${config.home.homeDirectory}/document";
        pictures = "${config.home.homeDirectory}/picture";
        videos = "${config.home.homeDirectory}/video";
        music = "${config.home.homeDirectory}/audio";
      };
      systemd.user.tmpfiles.rules = [
        "d %h/model 0755 - - -"
        "d %h/misc 0755 - - -"
      ];
      wayland.windowManager.sway = {
        enable = true;
        package = pkgs.swayfx;
        extraOptions = [ "--unsupported-gpu" ];
        extraConfig = ''
          corner_radius 4
          shadows enable
          shadows_on_csd enable
          shadow_blur_radius 20
          shadow_color #000000C0
          shadow_offset 0 2
          default_border pixel 2
          default_floating_border pixel 2
        '';
      };
      programs = {
        fuzzel.enable = true;
        swaylock.enable = true;
        mpv.enable = true;
        imv.enable = true;
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
        mako.enable = true;
        swayidle.enable = true;
      };
      home.packages = with pkgs; [
        swaybg
        grim
        slurp
        64gram-desktop
        zen-browser
        rqbit
        mupdf
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
        wl-clipboard
        wlr-randr
      ];
    };
  };

  #|---------------|
  #| customization |
  #|---------------|
  stylix.base16Scheme = {
    base00 = "0f1722";
    base01 = "16333c";
    base02 = "1c4d4c";
    base03 = "30394a";
    base04 = "8f896b";
    base05 = "e0dab6";
    base06 = "eeeacc";
    base07 = "fbf9ef";
    base08 = "ab3a5b";
    base09 = "d67527";
    base0A = "d1ad38";
    base0B = "25a397";
    base0C = "42d6cd";
    base0D = "4b8ba3";
    base0E = "68308a";
    base0F = "874618";
  };
  stylix.fonts = {
    serif = {
      package = pkgs.eb-garamond;
      name = "EB Garamond";
    };
    sansSerif = {
      package = pkgs.eb-garamond;
      name = "EB Garamond";
    };
    monospace = {
      package = pkgs.courier-prime;
      name = "Courier Prime";
    };
    sizes = {
      applications = 12;
      terminal = 12;
      desktop = 11;
      popups = 11;
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
