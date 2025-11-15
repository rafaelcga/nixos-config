{
  inputs,
  lib,
  flakeMeta,
  ...
}:
let
  mkNixosSystem =
    hostName: _:
    lib.nixosSystem {
      modules = [
        "${inputs.self}/overlays"
        "${inputs.self}/modules/nixos"
        "${inputs.self}/hosts/core.nix"
        "${inputs.self}/hosts/${hostName}"
      ];
      specialArgs = { inherit inputs flakeMeta hostName; };
    };
in
{
  flake.nixosConfigurations = lib.mapAttrs mkNixosSystem flakeMeta.hosts;
}
