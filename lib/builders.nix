{ inputs, lib, ... }:
{
  mkNixosSystem = host: {
    "${host}" = lib.nixosSystem {
      modules = [
        { networking.hostName = host; }
        "${inputs.self}/hosts/base.nix"
        "${inputs.self}/hosts/${host}"
      ];
      specialArgs = { inherit inputs lib; };
    };
  };
}
