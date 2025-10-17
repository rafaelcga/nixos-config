{ lib, pkgs, ... }:
{
  cachyos-settings = (import ./cachyos-settings) {
    inherit lib;
    inherit (pkgs) stdenv fetchFromGitHub;
  };
}
