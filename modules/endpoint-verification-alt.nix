{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.endpoint-verification;
in {
  options.services.endpoint-verification = {
    enable = mkEnableOption "Google Endpoint Verification";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.packageOverrides = pkgs: {
      endpoint-verification = pkgs.stdenv.mkDerivation {
        name = "endpoint-verification";
        version = "latest";
        
        # Fetch the package directly from Google's apt repository
        src = pkgs.fetchurl {
          url = "https://packages.cloud.google.com/apt/pool/endpoint-verification_latest_amd64.deb";
          # Nix will complain and show the right hash on first build
          hash = "";
        };
        
        # Use dpkg to install the .deb package
        nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];
        
        # Common dependencies for Google apps
        buildInputs = with pkgs; [
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
        
        # Simply extract the .deb package
        unpackPhase = ''
          dpkg-deb -x $src ./
        '';
        
        # Install files to the correct locations
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
          
          # Copy the Google opt directory to Nix store
          if [ -d opt ]; then
            mkdir -p $out/opt
            cp -r opt/* $out/opt/
          fi
          
          # Create proper symlinks to binaries in opt if needed
          if [ -d $out/opt/google/endpoint-verification/bin ]; then
            mkdir -p $out/bin
            for f in $out/opt/google/endpoint-verification/bin/*; do
              if [ -x "$f" ]; then
                ln -s "$f" "$out/bin/$(basename $f)"
              fi
            done
          fi
          
          # Fix desktop file if it exists
          if [ -f $out/opt/google/endpoint-verification/endpoint-verification.desktop ]; then
            mkdir -p $out/share/applications
            cp $out/opt/google/endpoint-verification/endpoint-verification.desktop $out/share/applications/
          fi
        '';
        
        # Add metadata
        meta = {
          description = "Google Endpoint Verification";
          homepage = "https://support.google.com/a/answer/9007320";
          platforms = [ "x86_64-linux" ];
        };
      };
    };
    
    # Add the package to system packages
    environment.systemPackages = [ pkgs.endpoint-verification ];
    
    # Store Google's apt key for reference
    environment.etc."trusted-keys/google-apt-key.gpg" = {
      source = pkgs.fetchurl {
        url = "https://packages.cloud.google.com/apt/doc/apt-key.gpg";
        # Leave the hash empty initially
        hash = "";
      };
      mode = "0444";
    };
  };
} 