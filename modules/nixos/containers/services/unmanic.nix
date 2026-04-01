{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.unmanic;
  inherit (config.modules.nixos.containers) user;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.unmanic = {
      containerPort = 8888;
      dataDir = "/var/lib/unmanic";
      gpuPassthrough = lib.mkDefault true;
    };
  }
  (lib.mkIf cfg.enable {
    containers.unmanic = {
      config = {
        imports = [ "${inputs.self}/modules/nixos/services/unmanic.nix" ];

        modules.nixos.unmanic = {
          enable = true;
          user = user.name;
          inherit (user) group;

          port = cfg.containerPort;
          openFirewall = true;
        };
      };
    };
  })
]
