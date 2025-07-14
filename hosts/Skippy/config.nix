{ config, pkgs, inputs, self, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/cron-jobs.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };

  networking.hostName = "skippy"; # Define your hostname.
  nix.settings.experimental-features = ["nix-command" "flakes"];
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Madrid";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };
  services = {
    xserver = {
      enable = true;
    };
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
    fprintd = {
      enable = true;
      tod.driver = pkgs.libfprint-2-tod1-elan;
    };
    xserver.xkb = {
      layout = "es";
      variant = "";
    };
    printing = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
  console.keyMap = "es";

  hardware = {
    pulseaudio = {
      enable = false;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vpl-gpu-rt
        intel-media-driver
        intel-vaapi-driver
        libvdpau-va-gl

      ];
    };
  };
  security.rtkit.enable = true;
  
  
  virtualisation.docker.enable = true;
  #sops = {
  #  defaultSopsFile = ../../secrets/sigtermPassword.yaml;
  #  age.keyFile = "/home/sigterm/.config/sops/age/keys.txt";
  #  secrets.user_password = {};
  #};
  users.users.sigterm = {
    isNormalUser = true;
    description = "SIGTERM";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" ];
    #hashedPasswordFile = config.sops.secrets.user_password.path;
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  programs.direnv.enable = true;
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
      "sigterm" = import ./home.nix;
    };
  };
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "sigterm" ];
  };
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
  environment.systemPackages = with pkgs; [
    _1password
    _1password-gui
  ];
  environment.sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.allowedUDPPorts = [];
  system.stateVersion = "24.11"; 
}
