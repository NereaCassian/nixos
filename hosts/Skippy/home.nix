{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.username = "sigterm";
  home.homeDirectory = "/home/sigterm";
  home.stateVersion = "25.05"; 
  home.packages = with pkgs; [
    nano
	  code-cursor
	  wget
	  curl
    vesktop
    ghostty
    google-cloud-sdk
    tfswitch
    fnm
    age
    sops
  ];
  home.file = {
    ".ssh/config" = {
      source = ./dots/.ssh/config;
      target = ".ssh/config_source";
      onChange = ''cat .ssh/config_source > .ssh/config && chmod 400 .ssh/config'';
    };
  };
  home.sessionVariables = {
    EDITOR = "cursor";
    NIX_CONFIG_PATH = "/home/sigterm/Documents/nixos";
    EMAIL = "nerea@sigterm.vodka";
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    shellAliases = {
      ".." = "cd ..";
      "nrebuild" = "sudo nixos-rebuild switch --flake $NIX_CONFIG_PATH/#skippy";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "z"];
      theme = "agnoster";
    };
  };
  programs.git = {
    enable = true;
    userName = "sigterm";
    userEmail = "nerea@sigterm.vodka";
  };
  programs.home-manager.enable = true;
}
