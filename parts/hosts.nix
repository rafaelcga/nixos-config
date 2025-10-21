{ inputs, lib, ... }:
let
  hosts = lib.local.listSubdirs "${inputs.self}/hosts";
in
{
  flake.nixosConfigurations = lib.mkMerge (map lib.local.mkNixosSystem hosts);
}
