{ inputs, lib, ... }:
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
        networking.hostName = host.name;
        system.stateVersion = host.stateVersion;
        nixpkgs.config.allowUnfree = true;
      };
      userConfig = {
        modules.nixos.user = lib.mkIf (user != null) {
          inherit (user) name description;
        };
      };
    in
    {
      "${host.name}" = lib.nixosSystem {
        inherit (host) system;
        modules = [
          coreConfig
          "${inputs.self}/overlays"
          "${inputs.self}/modules/nixos"
          "${inputs.self}/hosts/${host.name}"
          userConfig
        ];
        specialArgs = { inherit inputs; };
      };
    };
in
{
  flake.nixosConfigurations = lib.mkMerge (map mkNixosSystem hosts);
}
