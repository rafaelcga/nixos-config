{ config, ... }:
let
  inherit (config.modules.nixos) user;
in
{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

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
  };
  users.users.${user.name}.extraGroups = [ "networkmanager" ];

  networking = {
    nftables.enable = true;
    firewall.enable = true;
  };
}
