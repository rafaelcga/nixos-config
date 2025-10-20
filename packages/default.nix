{ lib, pkgs, ... }:
lib.local.callPackages {
  rootDir = ./.;
  inherit pkgs;
}
