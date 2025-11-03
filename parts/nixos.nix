{ inputs, lib, ... }:
let
  users = {
    "rafael" = {
      description = "Rafa Giménez";
    };
  };
  hosts = {
    "fractal" = {
      user = "rafael";
      system = "x86_64-linux";
      stateVersion = "25.11";
    };
    "beelink" = {
      user = "rafael";
      system = "x86_64-linux";
      stateVersion = "25.11";
    };
  };

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
          users.${config.user}
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
      specialArgs = { inherit inputs; };
    };
in
{
  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations = lib.mapAttrs mkNixosSystem hosts;
}
