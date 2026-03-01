{
  lib,
  stdenv,
  fetchFromGitHub,

  bash,
  hdparm,
}:

stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    tag = version;
    sha256 = "sha256-1py/RZaTJXGapqO22j/VZ7pT5xfRKmnyv+103btmK38=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/etc
    mkdir -p $out/lib

    cp -v -a $src/etc $out
    cp -v -a $src/usr/bin $out
    cp -v -a $src/usr/lib $out

    runHook postInstall
  '';

  postInstall = ''
    for f in $(find "$out/lib/udev/rules.d" -type f -name '*'); do
      substituteInPlace "$f" \
        --replace "/usr/bin/bash" "${lib.getExe bash}" \
        --replace "/usr/bin/hdparm" "${lib.getExe hdparm}"
    done
  '';

  meta = {
    description = "Settings used for CachyOS";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
