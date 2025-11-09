{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.2.12";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    rev = "v${version}";
    sha256 = "sha256-WknipQ447/r3FqnHqdCINYvYsoP6u4bbTnQeiXr42sk=";
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

  meta = with lib; {
    description = "CachyOS system settings for Nix";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
