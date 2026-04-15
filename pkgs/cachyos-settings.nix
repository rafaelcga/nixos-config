{
  lib,
  stdenv,
  fetchFromGitHub,
  bash,
  hdparm,
}:

stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.3.4";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    tag = version;
    sha256 = "sha256-NMoEAKQLPcKbNIuY5jH4iCurHFZa0vZXai+pn8ivCiM=";
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
    for f in "$out/lib/udev/rules.d/*.rules"; do
        substituteInPlace "$f" \
            --replace-quiet "/usr/bin/bash" "${lib.getExe bash}" \
            --replace-quiet "/usr/bin/hdparm" "${lib.getExe hdparm}" 2>/dev/null
    done
  '';

  meta = {
    description = "Settings used for CachyOS";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
