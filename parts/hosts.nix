{ inputs, lib, ... }:
let
  builders = import "${inputs.self}/lib/builders.nix" { inherit inputs lib; };
  utils = import "${inputs.self}/lib/utils.nix" { inherit inputs lib; };
  hosts = utils.listSubdirs "${inputs.self}/hosts";
in
{
  flake.nixosConfigurations = lib.mkMerge (map builders.mkNixosSystem hosts);
}
