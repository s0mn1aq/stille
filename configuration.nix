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
    initialPassword = "...";
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

  #|---------|
  #| storage |
  #|---------|
  programs.dconf.enable = true;
  programs.labwc.enable = true;
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
        desktop = null;
        publicShare = null;
        templates = null;
      };
      systemd.user.tmpfiles.rules = [
        "d %h/model 0755 - - -"
        "d %h/misc 0755 - - -"
      ];

      #|----------|
      #| software |
      #|----------|
      xdg.configFile."labwc/rc.xml".text = ''
        <?xml version="1.0"?>
        <labwc_config>
          <core>
            <gap>4</gap>
            <decoration>server</decoration>
          </core>
          <theme>
            <name>Deepwoken</name>
            <cornerRadius>4</cornerRadius>
            <keepBorder>yes</keepBorder>
            <dropShadows>yes</dropShadows>
            <dropShadowsOnTiled>no</dropShadowsOnTiled>
            <font place="ActiveWindow">
              <name>EB Garamond</name>
              <size>11</size>
            </font>
            <font place="InactiveWindow">
              <name>EB Garamond</name>
              <size>11</size>
            </font>
            <font place="MenuItem">
              <name>EB Garamond</name>
              <size>11</size>
            </font>
          </theme>
          <focus>
            <followMouse>no</followMouse>
            <raiseOnFocus>yes</raiseOnFocus>
          </focus>
          <placement>
            <policy>automatic</policy>
          </placement>
          <keyboard>
              <default />
              <keybind key="W-c">
                <action name="Execute" command="fuzzel" />
              </keybind>
              <keybind key="W-x">
                <action name="Execute" command="alacritty" />
              </keybind>
              <keybind key="W-z">
                <action name="Close" />
              </keybind>
            </keyboard>
          <mouse>
            <default />
            <context name="Root">
              <mousebind button="Left" action="Press">
                <action name="None" />
              </mousebind>
              <mousebind button="Right" action="Press">
                <action name="None" />
              </mousebind>
              <mousebind button="Middle" action="Press">
                <action name="None" />
              </mousebind>
            </context>
          </mouse>
        </labwc_config>
      '';
      xdg.configFile."labwc/environment".text = ''
        XDG_CURRENT_DESKTOP=labwc
      '';
      xdg.configFile."labwc/autostart" = {
        text = ''
          #!/bin/sh
          swaybg -i /etc/nixos/wallpaper.png -m fill &
          mako &
          swayidle -w timeout 600 'swaylock -f' &
        '';
        executable = true;
      };
      xdg.dataFile."themes/Deepwoken/openbox-3/themerc".text = ''
        window.active.border.color: #c8ba9e
        window.active.title.bg.color: #141f20
        window.active.label.text.color: #c8ba9e
        window.active.button.unpressed.image.color: #c8ba9e
        window.active.shadow.color: #141f20C0
        window.inactive.border.color: #26393b
        window.inactive.title.bg.color: #141f20
        window.inactive.label.text.color: #455a5c
        window.inactive.button.unpressed.image.color: #455a5c
        window.inactive.shadow.color: #141f2080
        border.width: 1
        padding.width: 5
        padding.height: 4
        window.handle.width: 2
        menu.items.bg.color: #141f20
        menu.items.text.color: #c8ba9e
        menu.items.active.bg.color: #26393b
        menu.items.active.text.color: #e3d7bf
        menu.title.bg.color: #1b292a
        menu.title.text.color: #c8ba9e
        menu.border.color: #c8ba9e
        menu.border.width: 2
        osd.bg.color: #141f20
        osd.border.color: #c8ba9e
        osd.label.text.color: #c8ba9e
      '';
      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            font = lib.mkForce "EB Garamond:size=14";
            width = 40;
            lines = 10;
            horizontal-pad = 24;
            vertical-pad = 14;
            inner-pad = 10;
          };
          border = {
            width = 2;
            radius = 4;
          };
        };
      };
      programs.swaylock.enable = true;
      programs.mpv.enable = true;
      programs.imv.enable = true;
      programs.alacritty.enable = true;
      programs.nushell.enable = true;
      programs.zellij.enable = true;
      programs.helix.enable = true;
      programs.yazi.enable = true;
      programs.eza.enable = true;
      programs.bat.enable = true;
      programs.zoxide.enable = true;
      programs.git.enable = true;
      programs.gitui.enable = true;
      programs.skim.enable = true;
      programs.fd.enable = true;
      programs.ripgrep.enable = true;
      programs.btop.enable = true;
      programs.fastfetch.enable = true;
      services = {
        mako.enable = true;
        swayidle.enable = true;
      };
      home.packages = with pkgs; [
        swaybg
        grim
        slurp
        _64gram
        librewolf
        rqbit
        playerctl
        brightnessctl
        pciutils
        usbutils
        ouch
        par2cmdline-turbo
        rage
        ffmpeg
        cpufetch
        (gpufetch.override { cudaSupport = true; })
        onefetch
        wl-clipboard
        wlr-randr
      ];
    };
  };

  #|---------------|
  #| customization |
  #|---------------|
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "EB Garamond" ];
        sansSerif = [ "EB Garamond" ];
        monospace = [ "Courier Prime" ];
      };
    };
    packages = with pkgs; [
      eb-garamond
      courier-prime
    ];
  };
  stylix = {
    enable = true;
    targets = {
      gtk.enable = false;
      qt.enable = false;
    };
    base16Scheme = {
      base00 = "141f20";
      base01 = "1b292a";
      base02 = "26393b";
      base03 = "455a5c";
      base04 = "786a59";
      base05 = "c8ba9e";
      base06 = "dcd0b6";
      base07 = "e3d7bf";
      base08 = "b54f38";
      base09 = "c4743d";
      base0A = "c2a265";
      base0B = "437c74";
      base0C = "5f9e95";
      base0D = "6d939c";
      base0E = "944258";
      base0F = "7a4a77";
    };
    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-dark";
      size = 24;
    };
    fonts = {
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
        applications = 11;
        terminal = 12;
        desktop = 11;
        popups = 10;
      };
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

  #|--------------|
  #| optimization |
  #|--------------|
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
