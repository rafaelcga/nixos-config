{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation rec {
  pname = "cachyos-settings";
  version = "1.2.11";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "CachyOS-Settings";
    tag = version;
    sha256 = "sha256-MRuhWZXzFDxzypY5oFueUzCKSsGGA9Mp+XKpXwzqSjE=";
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
