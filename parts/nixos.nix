{
  inputs,
  lib,
  flakeMeta,
  ...
}:
let
  mkNixosSystem =
    host: config:
    let
      coreConfig = {
        networking.hostName = host;
        system.stateVersion = config.stateVersion;
        nixpkgs = {
          hostPlatform = config.system;
          config.allowUnfree = true;
        };
      };

      userConfig = {
        modules.nixos.user = lib.mkMerge [
          { name = config.user; }
          flakeMeta.users.${config.user}
        ];
      };
    in
    lib.nixosSystem {
      modules = [
        coreConfig
        userConfig
        "${inputs.self}/overlays"
        "${inputs.self}/modules/nixos"
        "${inputs.self}/hosts/${host}"
      ];
      specialArgs = { inherit inputs flakeMeta; };
    };
in
{
  flake.nixosConfigurations = lib.mapAttrs mkNixosSystem flakeMeta.hosts;
}
