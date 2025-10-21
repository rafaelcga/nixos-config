{ lib, ... }:
let
  hosts = lib.local.listSubdirs ./.;
in
{
  flake.nixosConfigurations = lib.mkMerge (map lib.local.mkNixosSystem hosts);
}
