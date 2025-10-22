{
  withSystem,
  inputs,
  lib,
  ...
}:
let
  users = [
    {
      name = "rafael";
      description = "Rafa Giménez";
    }
  ];
  hosts = [
    {
      name = "fractal";
      user = "rafael";
      system = "x86_64-linux";
      stateVersion = "25.11";
    }
    {
      name = "beelink";
      user = "rafael";
      system = "x86_64-linux";
      stateVersion = "25.11";
    }
  ];

  mkNixosSystem =
    host:
    let
      user = lib.findFirst (user: user.name == host.user) null users;
      coreConfig = {
        nixpkgs = {
          overlays = [ inputs.self.overlays.default ];
          config.allowUnfree = true;
        };
        networking.hostName = host.name;
        system.stateVersion = host.stateVersion;
      };
      userConfig = {
        modules.nixos.user = lib.mkIf (user != null) {
          inherit (user) name description;
        };
      };
    in
    {
      "${host.name}" = withSystem host.system (
        { system, ... }:
        lib.nixosSystem {
          inherit system;
          modules = [
            "${inputs.self}/modules/nixos"
            "${inputs.self}/hosts/${host.name}"
            coreConfig
            userConfig
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
