{ pkgs }:
{
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  unmanic = pkgs.callPackage ./unmanic/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  crowdsec = pkgs.callPackage ./crowdsec.nix { };
  flatpak = pkgs.callPackage ./flatpak.nix { };
  jellyfin-ffmpeg = pkgs.callPackage ./jellyfin-ffmpeg.nix { };
}
