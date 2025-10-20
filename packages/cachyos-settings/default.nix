{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "cachyos-settings";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    rev = "master";
    sha256 = "sha256-HYWRedGi0pUcryqbvoXWw5etRrCMBM1FSxZ5kdBzZLc=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/etc
    mkdir -p $out/usr
    cp -v -a $src/etc $out
    cp -v -a $src/usr $out

    runHook postInstall
  '';

  meta = with lib; {
    description = "CachyOS system settings for Nix";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
