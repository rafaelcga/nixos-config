{
  flatpak,
  fetchurl,
}:

flatpak.overrideAttrs (finalAttrs: rec {
  version = "1.17.6";

  src = fetchurl {
    url = "https://github.com/flatpak/flatpak/releases/download/${version}/flatpak-${version}.tar.xz";
    hash = "sha256-pYzO1cRoeSwed4RxWeaH0/e+3owtRIPx8+8SKdUlU7I=";
  };
})
