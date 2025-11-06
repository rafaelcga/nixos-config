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

      # TODO: Finish and implement option (visibile false) for data directory
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
