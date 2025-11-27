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

  networkOpts = {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "10.200.200.0";
        description = "WireGuard home network IP";
      };

      mask = lib.mkOption {
        type = lib.types.int;
        default = 24;
        apply = builtins.toString;
        description = "Subnet mask for the WireGuard home network";
      };
    };
  };
in
{
  options.modules.nixos.home-vpn = {
    enable = lib.mkEnableOption "Enable remote access home VPN";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg-home";
      description = "Name of the WireGuard interface";
    };

    serverHostName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Name of the peer that will act as server";
    };

    network = lib.mkOption {
      type = lib.types.submodule networkOpts;
      default = { };
      description = "Configuration of the WireGuard network";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 51820;
      apply = builtins.toString;
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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

              sortedPeers = lib.sort lib.lessThan (lib.attrNames flakeMeta.hosts);
              clientPeers = lib.remove cfg.serverHostName sortedPeers;
              peers = [ cfg.serverHostName ] ++ clientPeers;

              networkIps =
                let
                  # Using imap1, index starts from 1
                  mkValuePairs = index: name: {
                    inherit name;
                    value = utils.addToLastOctet cfg.network.address index;
                  };
                in
                lib.listToAttrs (lib.imap1 mkValuePairs peers);

              mkForwardRules =
                action:
                let
                  ruleTemplate =
                    binName:
                    let
                      iptablesBin = lib.getExe' pkgs.iptables binName;
                    in
                    ''
                      ${iptablesBin} ${action} FORWARD -i ${cfg.interfaceName} -j ACCEPT
                      ${iptablesBin} ${action} FORWARD -o ${cfg.interfaceName} -j ACCEPT
                      ${iptablesBin} -t nat ${action} POSTROUTING \
                        -o ${defaultInterface} \
                        -j MASQUERADE
                    '';
                in
                lib.concatMapStringsSep "\n" ruleTemplate [
                  "iptables"
                  "ip6tables"
                ];

              postUpFile = pkgs.writeShellScript "wg_server_postup.sh" ''
                ${mkForwardRules "-A"}
              '';

              preDownFile = pkgs.writeShellScript "wg_server_predown.sh" ''
                ${mkForwardRules "-D"}
              '';
            in
            ''
              [Interface]
              PrivateKey = ${config.sops.placeholder."wireguard/home_vpn/${hostName}/private_key"}
              Address = ${networkIps.${hostName}}/${if cfg.isVpnServer then cfg.network.mask else "32"}
              ${
                if cfg.isVpnServer then
                  "ListenPort = ${cfg.listenPort}"
                else
                  "DNS = ${networkIps.${cfg.serverHostName}}"
              }
              ${lib.optionalString cfg.isVpnServer ''
                PostUp = ${postUpFile}
                PreDown = ${preDownFile}
              ''}
            ''
            + (
              if cfg.isVpnServer then
                let
                  clientIps = lib.filterAttrs (hostName: _: lib.elem hostName clientPeers) networkIps;
                  mkClientPeer = hostName: peerIp: ''
                    [Peer]
                    PublicKey = ${config.sops.placeholder."wireguard/home_vpn/${hostName}/public_key"}
                    AllowedIPs = ${peerIp}/32
                  '';
                  clientConfigs = lib.mapAttrsToList mkClientPeer clientIps;
                in
                lib.concatStringsSep "\n" clientConfigs
              else
                ''
                  [Peer]
                  PublicKey = ${config.sops.placeholder."wireguard/home_vpn/${cfg.serverHostName}/public_key"}
                  Endpoint = vpn.${config.sops.placeholder."web_domain"}:${cfg.listenPort}
                  AllowedIPs = 0.0.0.0/0, ::/0
                  PersistentKeepalive = 25
                ''
            );
        };
      }
      (lib.mkIf cfg.isVpnServer {
        networking = {
          nat = {
            enable = true;
            enableIPv6 = true;
            externalInterface = defaultInterface;
            internalInterfaces = [ cfg.interfaceName ];
          };

          wg-quick.interfaces."${cfg.interfaceName}" = {
            autostart = true;
            configFile = config.sops.templates."wireguard/${cfg.interfaceName}.conf".path;
          };

          firewall.allowedUDPPorts = [ cfg.listenPort ];
        };
      })
      (lib.mkIf (!cfg.isVpnServer) {
        networking.firewall.checkReversePath = "loose";

        systemd.services.nmcli-import-wg-home = rec {
          description = "Import WireGuard config into NetworkManager";
          wantedBy = [ "multi-user.target" ];
          after = [ "NetworkManager.service" ];
          requires = after;
          serviceConfig =
            let
              echo = lib.getExe' pkgs.coreutils "echo";
              nmcli = lib.getExe' pkgs.networkmanager "nmcli";
            in
            {
              Type = "oneshot";
              ExecStart = pkgs.writeShellScript "nmcli_import_wg_home.sh" ''
                if ! ${nmcli} connection show ${cfg.interfaceName} >/dev/null 2>&1; then
                  ${echo} "Importing WireGuard connection..."
                  ${nmcli} connection import \
                    type wireguard \
                    file "${config.sops.templates."wireguard/${cfg.interfaceName}.conf".path}"
                else
                  ${echo} "Connection ${cfg.interfaceName} already exists. Skipping import."
                fi
              '';
            };
        };
      })
    ]
  );
}
