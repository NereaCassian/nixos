{ config, lib, pkgs, ... }:

{
  options.services.endpoint-verification = {
    enable = lib.mkEnableOption "Google Endpoint Verification";
  };

  config = lib.mkIf config.services.endpoint-verification.enable {
    # Create a simple package using the latest .deb from Google
    nixpkgs.config.allowUnfree = true;
    
    environment.systemPackages = let
      endpoint-verification = pkgs.stdenvNoCC.mkDerivation {
        pname = "endpoint-verification";
        version = "latest";
        
        # Fetch directly from Google's apt repository
        src = pkgs.fetchurl {
          url = "https://packages.cloud.google.com/apt/pool/endpoint-verification_latest_amd64.deb";
          # Nix will show the right hash on first build attempt
          hash = "";
        };
        
        # Required tools
        nativeBuildInputs = with pkgs; [ dpkg autoPatchelfHook ];
        
        # Common dependencies for GUI applications
        buildInputs = with pkgs; [
          glib
          gtk3
          webkitgtk
        ];
        
        # Unpack the .deb file
        unpackPhase = "dpkg-deb -x $src .";
        
        # Install everything to the output directory
        installPhase = ''
          # Create output directories
          mkdir -p $out/bin $out/share/applications
          
          # Copy files from usr/ if they exist
          if [ -d usr ]; then
            cp -r usr/bin/* $out/bin/ || true
            cp -r usr/share/* $out/share/ || true
            cp -r usr/lib $out/ || true
          fi
          
          # Copy files from opt/ if they exist
          if [ -d opt ]; then
            mkdir -p $out/opt
            cp -r opt/* $out/opt/
            
            # Link main binary if it exists
            if [ -f opt/google/endpoint-verification/endpoint-verification ]; then
              ln -s $out/opt/google/endpoint-verification/endpoint-verification $out/bin/endpoint-verification
            fi
            
            # Copy desktop file
            if [ -f opt/google/endpoint-verification/endpoint-verification.desktop ]; then
              cp opt/google/endpoint-verification/endpoint-verification.desktop $out/share/applications/
            fi
          fi
          
          # Make binaries executable
          find $out/bin -type f -exec chmod +x {} \; || true
        '';
        
        meta = with lib; {
          description = "Google Endpoint Verification";
          homepage = "https://support.google.com/a/answer/9007320";
          platforms = platforms.linux;
          license = licenses.unfree;
        };
      };
    in [ endpoint-verification ];
  };
} 