{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.unmanic;
  inherit (config.modules.nixos.containers) user;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.unmanic = {
      uid = 8;
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
          package = pkgs.local.unmanic;
          inherit (user) group;
          openFirewall = true;

          inherit (cfg) dataDir;
          settings = {
            ui_port = cfg.containerPort;
            enable_library_scanner = true;
            run_full_scan_on_start = true;
            cache_path = "${cfg.dataDir}/cache"; # Don't use /tmp in case its in RAM
          };
        };
      };
    };
  })
]
