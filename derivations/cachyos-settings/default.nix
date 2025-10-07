{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.2.10";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    rev = "master";
    sha256 = "sha256-MRuhWZXzFDxzypY5oFueUzCKSsGGA9Mp+XKpXwzqSjE=";
  };

  installPhase = ''
    mkdir -p $out/etc
    mkdir -p $out/usr
    cp -r $src/etc/. $out/etc/
    cp -r $src/usr/. $out/usr/
  '';

  meta = with lib; {
    description = "CachyOS system settings for Nix";
    homepage = "https://github.com/CachyOS/CachyOS-Settings";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
