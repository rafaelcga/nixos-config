{ config, lib, ... }:
let
  cfg = config.modules.nixos.proton-vpn;
in
{
  options.modules.nixos.proton-vpn = {
    enable = lib.mkEnableOption "Enables Proton VPN through WireGuard";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "proton/wireguard/public_key" = { };
        "proton/wireguard/private_key" = { };
        "proton/wireguard/endpoint" = { };
      };
      templates."wg0.conf".content = ''
        [Interface]
        PrivateKey = ${config.sops.placeholder."proton/wireguard/private_key"}
        Address = 10.2.0.2/32
        DNS = 10.2.0.1

        [Peer]
        PublicKey = ${config.sops.placeholder."proton/wireguard/public_key"}
        AllowedIPs = 0.0.0.0/0, ::/0
        Endpoint = ${config.sops.placeholder."proton/wireguard/endpoint"}
      '';
    };

    networking.wg-quick.interfaces = {
      wg0 = {
        configFile = config.templates."wg0.conf".path;
      };
    };
  };
}
