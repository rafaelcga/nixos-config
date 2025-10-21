{ inputs, lib, ... }:
{
  mkNixosSystem = host: {
    "${host}" = lib.nixosSystem {
      modules = [
        "${inputs.self}/hosts/base.nix"
        "${inputs.self}/hosts/${host}"
      ];
      specialArgs = { inherit inputs lib; };
    };
  };
}
