{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  hdparm,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cachyos-settings";
  version = "1.4.4";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    tag = finalAttrs.version;
    hash = "sha256-PAwMBQ5WBjwU/UW66hLmCpUfseZ8QbHIQZOeD471skw=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r etc usr/lib $out/

    chmod +x $out/lib/udev/audio-pm-ctl
    patchShebangs $out/lib/udev/audio-pm-ctl

    for f in $out/lib/udev/rules.d/*.rules; do
      substituteInPlace $f \
        --replace-quiet /usr/bin/bash ${lib.getExe bash} \
        --replace-quiet /usr/bin/hdparm ${lib.getExe hdparm} \
        --replace-quiet /usr/lib/udev/audio-pm-ctl $out/lib/udev/audio-pm-ctl
    done

    runHook postInstall
  '';

  meta = {
    description = "Settings used for CachyOS";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
})
