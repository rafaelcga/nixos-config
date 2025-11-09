{ pkgs, callPackage }:
let
  pkgs-python = pkgs.extend (import ./python3);
in
{
  caddy-with-plugins = callPackage ./caddy-with-plugins/package.nix { };
  cachyos-settings = callPackage ./cachyos-settings.nix { };
  tidal-dl-ng = pkgs-python.callPackage ./tidal-dl-ng.nix { };
}
