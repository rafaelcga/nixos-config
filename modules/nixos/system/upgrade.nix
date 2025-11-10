{ config, lib, ... }:
let
  cfg = config.modules.nixos.upgrade;
in
{
  options.modules.nixos.upgrade = {
    enable = lib.mkEnableOption "Enable auto-upgrade";
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "github:rafaelcga/nixos-config";
      flags = [ "-L" ];

      dates = "04:00";
      randomizedDelaySec = "30min";
      fixedRandomDelay = true;
      allowReboot = true;
      rebootWindow = {
        lower = "04:00";
        upper = "06:00";
      };
      persistent = true;
    };
  };
}
