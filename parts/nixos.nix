{
  withSystem,
  inputs,
  lib,
  ...
}:
let
  hosts = [
    {
      name = "fractal";
      system = "x86_64-linux";
      stateVersion = "25.11";
    }
    {
      name = "beelink";
      system = "x86_64-linux";
      stateVersion = "25.11";
    }
  ];

  mkNixosSystem =
    host:
    let
      coreConfig = {
        nixpkgs = {
          overlays = [ inputs.self.overlays.default ];
          config.allowUnfree = true;
        };
        networking.hostName = host.name;
        system.stateVersion = host.stateVersion;
      };
    in
    {
      "${host.name}" = withSystem host.system (
        lib.nixosSystem {
          inherit (host) system;
          modules = [
            coreConfig
            "${inputs.self}/modules/nixos"
            "${inputs.self}/hosts/${host.name}"
          ];
          specialArgs = { inherit inputs; };
        }
      );
    };
in
{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations = lib.mkMerge (map mkNixosSystem hosts);
}
