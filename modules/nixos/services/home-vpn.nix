{
  inputs,
  config,
  lib,
  pkgs,
  flakeMeta,
  ...
}:
let
  inherit (config.modules.nixos.networking) defaultInterface;
  cfg = config.modules.nixos.home-vpn;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  iptables = lib.getExe pkgs.iptables;
  ip6tables = lib.getExe' pkgs.iptables "ip6tables";

  postUpFile = pkgs.writeShellScript "wg_server_postup.sh" ''
    ${iptables} -A FORWARD -i ${cfg.interfaceName} -j ACCEPT
    ${iptables} -A FORWARD -o ${cfg.interfaceName} -j ACCEPT
    ${iptables} -t nat -A POSTROUTING \
      -o ${defaultInterface} \
      -j MASQUERADE
    ${ip6tables} -A FORWARD -i ${cfg.interfaceName} -j ACCEPT
    ${ip6tables} -A FORWARD -o ${cfg.interfaceName} -j ACCEPT
    ${ip6tables} -t nat -A POSTROUTING \
      -o ${defaultInterface} \
      -j MASQUERADE
  '';

  preDownFile = pkgs.writeShellScript "wg_server_predown.sh" ''
    ${iptables} -D FORWARD -i ${cfg.interfaceName} -j ACCEPT
    ${iptables} -D FORWARD -o ${cfg.interfaceName} -j ACCEPT
    ${iptables} -t nat -D POSTROUTING \
      -o ${defaultInterface} \
      -j MASQUERADE
    ${ip6tables} -D FORWARD -i ${cfg.interfaceName} -j ACCEPT
    ${ip6tables} -D FORWARD -o ${cfg.interfaceName} -j ACCEPT
    ${ip6tables} -t nat -D POSTROUTING \
      -o ${defaultInterface} \
      -j MASQUERADE
  '';
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

    sops = {
      secrets =
        let
          mkPeerSecrets =
            hostName: _:
            let
              basePath = "wireguard/home_vpn/${hostName}";
            in
            {
              "${basePath}/public_key" = { };
              "${basePath}/private_key" = { };
            };
        in
        lib.mkMerge [
          (lib.concatMapAttrs mkPeerSecrets flakeMeta.hosts)
          { "web_domain" = { }; }
        ];

      templates."wireguard/${cfg.interfaceName}.conf".content =
        let
          inherit (config.networking) hostName;

          clientIps =
            let
              sortedPeers = lib.sort lib.lessThan (lib.attrNames flakeMeta.hosts);
              clientPeers = lib.remove cfg.serverHostName sortedPeers;
              # Using imap1, index starts from 1
              mkValuePairs = index: client: {
                name = client;
                value = utils.addToLastOctet cfg.internalIp index;
              };

            in
            lib.listToAttrs (lib.imap1 mkValuePairs clientPeers);

          interfaceConfig = lib.concatStringsSep "\n" [
            ''
              [Interface]
              PrivateKey = ${config.sops.placeholder."wireguard/home_vpn/${hostName}/private_key"}
            ''
            (
              if cfg.isVpnServer then
                ''
                  Address = ${cfg.internalIp}/24
                  ListenPort = ${builtins.toString cfg.listenPort}
                ''
              else
                let
                  clientIp = clientIps.${hostName};
                in
                ''
                  Address = ${clientIp}/32
                  DNS = ${cfg.internalIp}
                ''
            )
            (lib.optionalString cfg.isVpnServer ''
              PostUp = ${postUpFile}
              PreDown = ${preDownFile}
            '')
          ];

          peersConfig =
            if cfg.isVpnServer then
              let
                mkClientPeer = name: peerIp: ''
                  [Peer]
                  PublicKey = ${config.sops.placeholder."wireguard/home_vpn/${name}/public_key"}
                  AllowedIPs = ${peerIp}/32
                '';
                clientConfigs = lib.mapAttrsToList mkClientPeer clientIps;
              in
              lib.concatStringsSep "\n\n" clientConfigs
            else
              ''
                [Peer]
                PublicKey = ${config.sops.placeholder."wireguard/home_vpn/${cfg.serverHostName}/public_key"}
                Endpoint = vpn.${config.sops.placeholder."web_domain"}:${builtins.toString cfg.listenPort}
                AllowedIPs = 0.0.0.0/0, ::/0
              '';
        in
        lib.concatStringsSep "\n\n" [
          interfaceConfig
          peersConfig
        ];
    };

    networking = lib.mkMerge [
      {
        wg-quick.interfaces."${cfg.interfaceName}" = {
          autostart = cfg.isVpnServer;
          configFile = config.sops.templates."wireguard/${cfg.interfaceName}.conf".path;
        };
      }
      (lib.mkIf cfg.isVpnServer {
        nat = {
          enable = true;
          enableIPv6 = true;
          externalInterface = defaultInterface;
          internalInterfaces = [ cfg.interfaceName ];
        };

        firewall.allowedUDPPorts = [ cfg.listenPort ];
      })
    ];
  };
}
