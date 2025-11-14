{
  inputs,
  config,
  lib,
  pkgs,
  flakeMeta ? {
    users = { };
    hosts = { };
  },
  ...
}:
let
  inherit (config.modules.nixos.networking) defaultInterface;
  cfg = config.modules.nixos.wireguard;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  doHomeVpnConfig = cfg.configFile == null && cfg.serverHostName != null;

  firewallRules =
    let
      iptables = "${pkgs.iptables}/bin/iptables";
      ip6tables = "${pkgs.iptables}/bin/ip6tables";
      nft = "${pkgs.nftables}/bin/nft";
      wg = "${pkgs.wireguard-tools}/bin/wg";
    in
    if config.networking.nftables.enable then
      {
        serverPostUp = ''
          ${nft} add rule inet filter FORWARD \
            {iifname, oifname} "%i" \
            counter accept
          ${nft} add rule inet nat POSTROUTING \
            oifname "${defaultInterface}" \
            counter masquerade
        '';
        serverPreDown = ''
          ${nft} delete rule inet filter FORWARD \
            {iifname, oifname} "%i" \
            counter accept
          ${nft} delete rule inet nat POSTROUTING \
            oifname "${defaultInterface}" \
            counter masquerade
        '';
        killSwitchPostUp = ''
          ${nft} insert rule inet filter output \
            oifname != "%i" \
            mark != $(${wg} show %i fwmark) \
            fib daddr type != local \
            counter reject
        '';
        killSwitchPreDown = ''
          ${nft} delete rule inet filter output \
            oifname != "%i" \
            mark != $(${wg} show %i fwmark) \
            fib daddr type != local \
            counter reject
        '';
      }
    else
      {
        serverPostUp = ''
          ${iptables} -A FORWARD -i %i -j ACCEPT
          ${iptables} -A FORWARD -o %i -j ACCEPT
          ${iptables} -t nat -A POSTROUTING \
            -o ${defaultInterface} \
            -j MASQUERADE
          ${ip6tables} -A FORWARD -i %i -j ACCEPT
          ${ip6tables} -A FORWARD -o %i -j ACCEPT
          ${ip6tables} -t nat -A POSTROUTING \
            -o ${defaultInterface} \
            -j MASQUERADE
        '';
        serverPreDown = ''
          ${iptables} -D FORWARD -i %i -j ACCEPT
          ${iptables} -D FORWARD -o %i -j ACCEPT
          ${iptables} -t nat -D POSTROUTING \
            -o ${defaultInterface} \
            -j MASQUERADE
          ${ip6tables} -D FORWARD -i %i -j ACCEPT
          ${ip6tables} -D FORWARD -o %i -j ACCEPT
          ${ip6tables} -t nat -D POSTROUTING \
            -o ${defaultInterface} \
            -j MASQUERADE
        '';
        killSwitchPostUp = ''
          ${iptables} -I OUTPUT \
            ! -o %i \
            -m mark ! --mark $(${wg} show %i fwmark) \
            -m addrtype ! --dst-type LOCAL \
            -j REJECT
          ${ip6tables} -I OUTPUT \
            ! -o %i \
            -m mark ! --mark $(${wg} show %i fwmark) \
            -m addrtype ! --dst-type LOCAL \
            -j REJECT
        '';
        killSwitchPreDown = ''
          ${iptables} -D OUTPUT \
            ! -o %i \
            -m mark ! --mark $(${wg} show %i fwmark) \
            -m addrtype ! --dst-type LOCAL \
            -j REJECT
          ${ip6tables} -D OUTPUT \
            ! -o %i \
            -m mark ! --mark $(${wg} show %i fwmark) \
            -m addrtype ! --dst-type LOCAL \
            -j REJECT
        '';
      };
in
{
  options.modules.nixos.wireguard = {
    enable = lib.mkEnableOption "Enables Proton VPN through WireGuard";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the WireGuard configuration file";
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

    useKillSwitch = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Setup kill-switch for WireGuard interface";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion =
              cfg.serverHostName == null || lib.elem cfg.serverHostName (lib.attrNames flakeMeta.hosts);
            message = ''
              The specified `serverHostName` (${cfg.serverHostName}) is not
              a valid host.
            '';
          }
        ];

        networking.wg-quick.interfaces."${cfg.interfaceName}" = {
          autostart = cfg.isVpnServer;
          postUp =
            lib.optionals cfg.isVpnServer [ firewallRules.serverPostUp ]
            ++ lib.optionals cfg.useKillSwitch [ firewallRules.killSwitchPostUp ];
          preDown =
            lib.optionals cfg.isVpnServer [ firewallRules.serverPreDown ]
            ++ lib.optionals cfg.useKillSwitch [ firewallRules.killSwitchPreDown ];
        };
      }
      (lib.mkIf doHomeVpnConfig {
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
                    value = utils.addToAddress cfg.internalIp index;
                  };

                in
                lib.listToAttrs (lib.imap1 mkValuePairs clientPeers);

              interfaceConfig =
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
                  '';

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
            ''
              [Interface]
              ${interfaceConfig}
              PrivateKey = ${config.sops.placeholder."wireguard/home_vpn/${hostName}/private_key"}

              ${peersConfig}
            '';
        };

        networking = {
          nat = lib.mkIf cfg.isVpnServer {
            enable = true;
            enableIPv6 = true;
            externalInterface = defaultInterface;
            internalInterfaces = [ cfg.interfaceName ];
          };

          wg-quick.interfaces."${cfg.interfaceName}".configFile =
            config.sops.templates."wireguard/${cfg.interfaceName}.conf".path;
        };
      })
      (lib.mkIf (cfg.configFile != null) {
        networking.wg-quick.interfaces."${cfg.interfaceName}".configFile = cfg.configFile;
      })
    ]
  );
}
