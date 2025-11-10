{ pkgs }:
let
  pkgs-python = pkgs.extend (import ./python3);
in
{
  inherit (pkgs-python.python3.pkgs)
    pyqtdarktheme-fork
    rich
    typer
    ;
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
  tidal-dl-ng = pkgs-python.callPackage ./tidal-dl-ng.nix { };
}
