{
  config,
  lib,
  pkgs,
  flakeMeta,
  ...
}:
let
  inherit (config.modules.nixos.networking) defaultInterface;
  cfg = config.modules.nixos.home-vpn;

  # TODO: Rewrite as shell scripts and include in configFile (cannot merge
  # default options with config file)
  # firewallRules =
  #   let
  #     iptables = "${pkgs.iptables}/bin/iptables";
  #     ip6tables = "${pkgs.iptables}/bin/ip6tables";
  #     nft = "${pkgs.nftables}/bin/nft";
  #   in
  #   if config.networking.nftables.enable then
  #     {
  #       serverPostUp = ''
  #         ${nft} add rule inet filter FORWARD \
  #           {iifname, oifname} "%i" \
  #           counter accept
  #         ${nft} add rule inet nat POSTROUTING \
  #           oifname "${defaultInterface}" \
  #           counter masquerade
  #       '';
  #       serverPreDown = ''
  #         ${nft} delete rule inet filter FORWARD \
  #           {iifname, oifname} "%i" \
  #           counter accept
  #         ${nft} delete rule inet nat POSTROUTING \
  #           oifname "${defaultInterface}" \
  #           counter masquerade
  #       '';
  #     }
  #   else
  #     {
  #       serverPostUp = ''
  #         ${iptables} -A FORWARD -i %i -j ACCEPT
  #         ${iptables} -A FORWARD -o %i -j ACCEPT
  #         ${iptables} -t nat -A POSTROUTING \
  #           -o ${defaultInterface} \
  #           -j MASQUERADE
  #         ${ip6tables} -A FORWARD -i %i -j ACCEPT
  #         ${ip6tables} -A FORWARD -o %i -j ACCEPT
  #         ${ip6tables} -t nat -A POSTROUTING \
  #           -o ${defaultInterface} \
  #           -j MASQUERADE
  #       '';
  #       serverPreDown = ''
  #         ${iptables} -D FORWARD -i %i -j ACCEPT
  #         ${iptables} -D FORWARD -o %i -j ACCEPT
  #         ${iptables} -t nat -D POSTROUTING \
  #           -o ${defaultInterface} \
  #           -j MASQUERADE
  #         ${ip6tables} -D FORWARD -i %i -j ACCEPT
  #         ${ip6tables} -D FORWARD -o %i -j ACCEPT
  #         ${ip6tables} -t nat -D POSTROUTING \
  #           -o ${defaultInterface} \
  #           -j MASQUERADE
  #       '';
  #     };
in
{
  options.modules.nixos.home-vpn = {
    enable = lib.mkEnableOption "Enable remote access home VPN";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };

    serverHostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Name of the peer that will act as server";
    };

    internalIp = lib.mkOption {
      type = lib.types.str;
      default = "10.200.200.1";
      description = "Address of the server in the WireGuard VPN";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      description = "Listening port of the server in the WireGuard VPN";
    };

    isVpnServer = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      internal = true;
      description = "Whether host acts as WireGuard server";

      default = config.networking.hostName == cfg.serverHostName;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.serverHostName != null && lib.elem cfg.serverHostName (lib.attrNames flakeMeta.hosts);
        message = ''
          The specified `serverHostName` (${cfg.serverHostName}) is not
          a valid host.
        '';
      }
    ];

    networking.wg-quick.interfaces."${cfg.interfaceName}" = {
      autostart = cfg.isVpnServer;
    };
  };
}
