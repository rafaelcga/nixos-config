{ lib, pkgs }:
let
  pkgs-python = pkgs.extend (import ./python3 { inherit lib; });
in
{
  inherit (pkgs-python.python3.pkgs)
    asreview
    asreview-dory
    ;
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  papermc = pkgs.callPackage ./papermc/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  crowdsec = pkgs.callPackage ./crowdsec.nix { };
}
