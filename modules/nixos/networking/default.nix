{
  config,
  lib,
  hostName,
  ...
}:
let
  cfg = config.modules.nixos.networking;
in
{
  options.modules.nixos.networking = {
    enable = lib.mkEnableOption "networking configuration";
  };

  config = lib.mkIf cfg.enable {
    networking = {
      inherit hostName;
      networkmanager = {
        enable = true;
        wifi.backend = "iwd";
      };
      nftables.enable = true;
      firewall = {
        enable = true;
        filterForward = true;
      };
    };
  };
}
