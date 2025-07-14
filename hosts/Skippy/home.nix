{ config, pkgs, ... }:
  let
    gdk = pkgs.google-cloud-sdk.withExtraComponents( with pkgs.google-cloud-sdk.components; [
      gke-gcloud-auth-plugin
    ]);
    ghostty = pkgs.ghostty.overrideAttrs (_: {
      preBuild = ''
        shopt -s globstar
        sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
        shopt -u globstar
      '';
    });
  in
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
    terraform
    terraform-ls
    fnm
    age
    sops
    kdePackages.kate
    google-chrome
    neofetch
    libcxx
    vscode
    spotify
    k9s
    kubectl
    kubectx
    gdk
    fzf
    slack
    ollama
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
    PATH="$PATH:/home/sigterm/bin";
  };
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    shellAliases = {
      ".." = "cd ..";
      "nrebuild" = "sudo nix flake update && sudo nixos-rebuild switch --upgrade --flake $NIX_CONFIG_PATH/#skippy";
      "ndev" = "nix develop -c $SHELL";
    };
    oh-my-zsh = {
      enable = true;
      plugins = [ 
        "git" 
        "sudo" 
        "z"
        ];
      theme = "strug";
    };
  };
  programs.git = {
    enable = true;
    userName = "Nerea Kalandadze";
    userEmail = "nkalandadze@kavehome.com";
  };
  programs.home-manager.enable = true;
}
