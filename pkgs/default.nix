{
  pkgs,
  prev ? pkgs,
}:
{
  local = {
    caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
    unmanic = pkgs.callPackage ./unmanic/package.nix { };
    cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  };

  crowdsec = pkgs.callPackage ./crowdsec.nix { }; # TODO: use overrideAttrs when PR merges
  flatpak = pkgs.callPackage ./flatpak.nix { inherit (prev) flatpak; };
  jellyfin-ffmpeg = pkgs.callPackage ./jellyfin-ffmpeg.nix { inherit (prev) jellyfin-ffmpeg; };
}
