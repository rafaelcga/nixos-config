{
  flatpak,
  fetchurl,
}:

flatpak.overrideAttrs (finalAttrs: {
  version = "1.17.6";

  src = fetchurl {
    url = "https://github.com/flatpak/flatpak/releases/download/${finalAttrs.version}/flatpak-${finalAttrs.version}.tar.xz";
    hash = "sha256-dh/zugDJmib5FMaZnpCxKlTKsZzqWIhBPxfkbuYY2P4=";
  };
})
