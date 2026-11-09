{
  lib,
  stdenv,
  fetchFromGitHub,
  bash,
  hdparm,
}:

stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    tag = version;
    sha256 = "sha256-9ffWReUeZquH3Ljcv8wtnlr6sQpgxHBN6irVllGtGxU=";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -rv etc $out/
    cp -rv usr/lib $out/

    runHook postInstall
  '';

  postInstall = ''
    chmod +x $out/lib/udev/audio-pm-ctl
    patchShebangs $out/lib/udev/audio-pm-ctl

    for f in $out/lib/udev/rules.d/*.rules; do
        substituteInPlace $f \
            --replace-quiet /usr/bin/bash ${lib.getExe bash} \
            --replace-quiet /usr/bin/hdparm ${lib.getExe hdparm} \
            --replace-quiet /usr/lib/udev/audio-pm-ctl $out/lib/udev/audio-pm-ctl
    done
  '';

  meta = {
    description = "Settings used for CachyOS";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
