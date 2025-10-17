{ lib, pkgs, ... }:
lib.local.importModules {
  rootDir = ./.;
  callArgs = pkgs // {
    inherit lib;
  };
}
