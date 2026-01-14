{ pkgs }:
let
  pkgs-python = pkgs.extend (import ./python3);
in
{
  inherit (pkgs-python.python3.pkgs)
    pyqtdarktheme-fork
    rich
    tidalapi
    typer
    ;
  caddy-with-plugins = pkgs.callPackage ./caddy-with-plugins/package.nix { };
  papermc = pkgs.callPackage ./papermc/package.nix { };
  cachyos-settings = pkgs.callPackage ./cachyos-settings.nix { };
}
