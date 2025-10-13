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
    services.openssh.enable = true;
    networking = {
      inherit hostName;
      wireless.iwd = {
        enable = true;
        settings = {
          Network = {
            EnableIPv6 = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
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
