{ inputs, lib, ... }:
let
  utils = import "${inputs.self}/lib/utils.nix" { inherit inputs lib; };
  hosts = utils.listSubdirs "${inputs.self}/hosts";

  mkNixosSystem = host: {
    "${host}" = lib.nixosSystem {
      modules = [
        { networking.hostName = host; }
        "${inputs.self}/modules/nixos"
        "${inputs.self}/hosts/base.nix"
        "${inputs.self}/hosts/${host}"
      ];
      specialArgs = { inherit inputs; };
    };
  };
in
{
  flake.nixosConfigurations = lib.mkMerge (map mkNixosSystem hosts);
}
