{ lib
, stdenv
, fetchurl
, dpkg
, makeWrapper
, autoPatchelfHook
, openssl
, curl
, systemd
, dbus
, zlib
, glibc
, writeScript
}:

stdenv.mkDerivation rec {
  pname = "endpoint-verification";
  version = "2023.12.18.c591921611-00";

  src = fetchurl {
    url = "https://packages.cloud.google.com/apt/pool/endpoint-verification/endpoint-verification_${version}_amd64_0ed3d7aced2a9858c943a958c4c8ee9a.deb";
    sha256 = "557e0ce3527e2bc3a29906cbc8adfbae5e469fad9cf8dd2ca75d04a9ddc3dcc5";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    openssl
    curl
    systemd
    dbus
    zlib
    glibc
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    
    # Create output directories
    mkdir -p $out/bin
    mkdir -p $out/opt/google
    mkdir -p $out/lib/systemd/user
    mkdir -p $out/etc/opt/chrome/native-messaging-hosts
    mkdir -p $out/etc/chromium/native-messaging-hosts
    mkdir -p $out/share/applications
    
    # Copy the main application directory
    if [ -d opt/google/endpoint-verification ]; then
      cp -r opt/google/endpoint-verification $out/opt/google/
      
      # Find and make executables
      find $out/opt/google/endpoint-verification -type f -executable -exec chmod +x {} \;
      
      # Create wrapper for the main binary if it exists
      if [ -f $out/opt/google/endpoint-verification/bin/endpoint_verification ]; then
        makeWrapper $out/opt/google/endpoint-verification/bin/endpoint_verification $out/bin/endpoint_verification
      fi
    fi
    
    # Copy systemd service files
    if [ -d lib/systemd ]; then
      cp -r lib/systemd/* $out/lib/systemd/
    fi
    
    # Copy Chrome native messaging configuration
    if [ -d etc/opt/chrome/native-messaging-hosts ]; then
      cp -r etc/opt/chrome/native-messaging-hosts/* $out/etc/opt/chrome/native-messaging-hosts/
    fi
    
    # Copy Chromium native messaging configuration  
    if [ -d etc/chromium/native-messaging-hosts ]; then
      cp -r etc/chromium/native-messaging-hosts/* $out/etc/chromium/native-messaging-hosts/
    fi
    
    # Copy any desktop files
    if [ -d usr/share/applications ]; then
      cp -r usr/share/applications/* $out/share/applications/
    fi
    
    runHook postInstall
  '';

  postFixup = ''
    # Patch any shell scripts
    find $out -type f -executable -exec grep -l "^#!" {} \; | while read script; do
      patchShebangs "$script"
    done
    
    # Fix hardcoded paths in native messaging host configurations
    find $out -name "*.json" -exec sed -i 's|/opt/google/endpoint-verification|'$out'/opt/google/endpoint-verification|g' {} \;
    
    # Fix any hardcoded paths in systemd service files
    find $out -name "*.service" -exec sed -i 's|/opt/google/endpoint-verification|'$out'/opt/google/endpoint-verification|g' {} \;
  '';

  meta = with lib; {
    description = "Google Endpoint Verification native helper for Chrome/Chromium";
    longDescription = ''
      Google Endpoint Verification is a Chrome/Chromium extension that helps
      administrators control device access to organizational data. This package
      provides the native helper application required for the extension to
      function on Linux systems.
      
      The package includes:
      - Native messaging helper for Chrome/Chromium integration
      - Device attestation and certificate management components  
      - System service for background device monitoring
      
      This is required for organizations using Google Workspace's Context-Aware
      Access features and device management policies.
    '';
    homepage = "https://support.google.com/a/users/answer/9018161";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
} 