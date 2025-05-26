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
    mkdir -p $out/etc/init.d
    mkdir -p $out/etc/opt/chrome/native-messaging-hosts
    mkdir -p $out/opt/google/endpoint-verification/bin
    mkdir -p $out/opt/google/endpoint-verification/var/lib
    mkdir -p $out/usr/lib/mozilla/native-messaging-hosts
    
    # Copy init.d script
    if [ -f etc/init.d/endpoint-verification ]; then
      cp etc/init.d/endpoint-verification $out/etc/init.d/
      chmod +x $out/etc/init.d/endpoint-verification
    fi
    
    # Copy Chrome native messaging configuration
    if [ -f etc/opt/chrome/native-messaging-hosts/com.google.endpoint_verification.api_helper.json ]; then
      cp etc/opt/chrome/native-messaging-hosts/com.google.endpoint_verification.api_helper.json $out/etc/opt/chrome/native-messaging-hosts/
    fi
    
    # Copy main application files
    if [ -d opt/google/endpoint-verification ]; then
      # Copy binaries
      if [ -f opt/google/endpoint-verification/bin/apihelper ]; then
        cp opt/google/endpoint-verification/bin/apihelper $out/opt/google/endpoint-verification/bin/
        chmod +x $out/opt/google/endpoint-verification/bin/apihelper
      fi
      
      if [ -f opt/google/endpoint-verification/bin/device_state.sh ]; then
        cp opt/google/endpoint-verification/bin/device_state.sh $out/opt/google/endpoint-verification/bin/
        chmod +x $out/opt/google/endpoint-verification/bin/device_state.sh
      fi
      
      # Copy var/lib directory
      if [ -d opt/google/endpoint-verification/var/lib ]; then
        cp -r opt/google/endpoint-verification/var/lib $out/opt/google/endpoint-verification/var/
      fi
      
      # Create symlinks to binaries
      ln -s $out/opt/google/endpoint-verification/bin/apihelper $out/bin/endpoint-verification-apihelper
    fi
    
    # Copy Mozilla native messaging configuration
    if [ -f usr/lib/mozilla/native-messaging-hosts/com.google.endpoint_verification.api_helper.json ]; then
      cp usr/lib/mozilla/native-messaging-hosts/com.google.endpoint_verification.api_helper.json $out/usr/lib/mozilla/native-messaging-hosts/
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
    
    # Fix any hardcoded paths in init.d script
    if [ -f $out/etc/init.d/endpoint-verification ]; then
      sed -i 's|/opt/google/endpoint-verification|'$out'/opt/google/endpoint-verification|g' $out/etc/init.d/endpoint-verification
    fi
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
    maintainers = [ "me i guess" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
} 