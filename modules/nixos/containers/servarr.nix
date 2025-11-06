{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.containers.instances.servarr or { enable = false; };
in
{
  config = lib.mkIf cfg.enable {
    containers.servarr = {
      enableTun = true;

      config = {
        imports = [ "${inputs.self}/modules/nixos" ];

        services = {
          lidarr = {
            enable = true;
          };
          radarr = {
            enable = true;
          };
          sonarr = {
            enable = true;
          };
          prowlarr = {
            enable = true;
          };
        };

        modules.nixos.proton-vpn.enable = true;
      };
    };
  };
}
