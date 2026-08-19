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
      gtk.enable = true;
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
            <cornerRadius>2</cornerRadius>
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
        window.active.border.color: #519389
        window.active.title.bg.color: #1b292a
        window.active.label.text.color: #d5c7ad
        window.active.button.unpressed.image.color: #d5c7ad
        window.active.shadow.color: #1b292aC0
        window.inactive.border.color: #223638
        window.inactive.title.bg.color: #1b292a
        window.inactive.label.text.color: #506568
        window.inactive.button.unpressed.image.color: #506568
        window.inactive.shadow.color: #1b292a80
        border.width: 3
        padding.width: 5
        padding.height: 4
        window.handle.width: 3
        menu.items.bg.color: #1b292a
        menu.items.text.color: #d5c7ad
        menu.items.active.bg.color: #2d4649
        menu.items.active.text.color: #f2e8d3
        menu.title.bg.color: #223638
        menu.title.text.color: #d5c7ad
        menu.border.color: #519389
        menu.border.width: 2
        osd.bg.color: #1b292a
        osd.border.color: #519389
        osd.label.text.color: #d5c7ad
      '';
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
    base16Scheme = {
      base00 = "1b292a";
      base01 = "223638";
      base02 = "2d4649";
      base03 = "506568";
      base04 = "887a68";
      base05 = "d5c7ad";
      base06 = "e6d9bf";
      base07 = "f2e8d3";
      base08 = "c85d43";
      base09 = "d9824c";
      base0A = "d4b375";
      base0B = "519389";
      base0C = "72b2a8";
      base0D = "80a8b0";
      base0E = "a84f68";
      base0F = "8d588a";
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
