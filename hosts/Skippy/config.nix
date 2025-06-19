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

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.fprintd.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-elan;
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };
  console.keyMap = "es";
  services.printing.enable = true;
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true; 
  hardware.bluetooth.powerOnBoot = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  
  virtualisation.docker.enable = true;
  #sops = {
  #  defaultSopsFile = ../../secrets/sigtermPassword.yaml;
  #  age.keyFile = "/home/sigterm/.config/sops/age/keys.txt";
  #  secrets.user_password = {};
  #};
  users.users.sigterm = {
    isNormalUser = true;
    description = "SIGTERM";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
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
  environment.systemPackages = with pkgs; [
    _1password
    _1password-gui
  ];
  networking.firewall.allowedTCPPorts = [22];
  networking.firewall.allowedUDPPorts = [];
  system.stateVersion = "24.11"; 
}
