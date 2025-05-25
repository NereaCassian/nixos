{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.endpoint-verification;
in {
  options.services.endpoint-verification = {
    enable = mkEnableOption "Google Endpoint Verification";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        endpoint-verification = prev.stdenv.mkDerivation {
          name = "endpoint-verification";
          version = "latest";
          
          # We're not using the local .deb file anymore
          src = prev.fetchurl {
            url = "https://packages.cloud.google.com/apt/pool/endpoint-verification_latest_amd64.deb";
            # Leave the hash empty initially; Nix will tell us the correct hash on first build
            hash = "";
          };
          
          nativeBuildInputs = with prev; [
            dpkg
            autoPatchelfHook
          ];
          
          buildInputs = with prev; [
            stdenv.cc.cc.lib
            glib
            gtk3
            atk
            cairo
            pango
            gdk-pixbuf
            libsoup
            webkitgtk
          ];
          
          unpackPhase = ''
            dpkg-deb -x $src ./
          '';
          
          installPhase = ''
            mkdir -p $out
            
            # Copy usr directory if it exists
            if [ -d usr ]; then
              cp -r usr/* $out/
            fi
            
            # Fix executable permissions
            if [ -d $out/bin ]; then
              chmod +x $out/bin/* || true
            fi
            
            # Create desktop entry in the correct location
            mkdir -p $out/share/applications
            if [ -f opt/google/endpoint-verification/endpoint-verification.desktop ]; then
              cp opt/google/endpoint-verification/endpoint-verification.desktop $out/share/applications/
            fi
            
            # Copy any libraries from opt directory
            if [ -d opt/google/endpoint-verification ]; then
              mkdir -p $out/opt/google
              cp -r opt/google/endpoint-verification $out/opt/google/
            fi
          '';
          
          meta = {
            description = "Google Endpoint Verification";
            homepage = "https://support.google.com/a/answer/9007320";
            platforms = [ "x86_64-linux" ];
          };
        };
      })
    ];
    
    environment.systemPackages = [ pkgs.endpoint-verification ];
    
    # Add Google's apt key to trusted keys (for reference only, not used by Nix directly)
    environment.etc."trusted-keys/google-apt-key.gpg" = {
      source = pkgs.fetchurl {
        url = "https://packages.cloud.google.com/apt/doc/apt-key.gpg";
        # Leave the hash empty initially; Nix will tell us the correct hash on first build
        hash = "";
      };
      mode = "0444";
    };
  };
} 