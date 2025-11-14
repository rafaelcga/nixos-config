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
  cfg = config.modules.nixos.wireguard;

  utils = import "${inputs.self}/lib/utils.nix" { inherit lib; };

  iptables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
  nft = "${pkgs.nftables}/bin/nft";
  wg = "${pkgs.wireguard-tools}/bin/wg";

  doHomeVpnConfig = cfg.configFile == null && cfg.serverHostName != null;

  serverPostUp =
    if config.networking.nftables.enable then
      ''
        ${nft} add rule ip filter FORWARD \
          {iifname, oifname} "%i" \
          counter accept
        ${nft} add rule ip nat POSTROUTING \
          oifname "${config.modules.nixos.networking.defaultInterface}" \
          counter masquerade
      ''
    else
      ''
        ${iptables} -A FORWARD -i %i -j ACCEPT
        ${iptables} -A FORWARD -o %i -j ACCEPT
        ${iptables} -t nat -A POSTROUTING \
          -o ${config.modules.nixos.networking.defaultInterface} \
          -j MASQUERADE
      '';

  serverPreDown =
    if config.networking.nftables.enable then
      ''
        ${nft} delete rule ip filter FORWARD \
          {iifname, oifname} "%i" \
          counter accept
        ${nft} delete rule ip nat POSTROUTING \
          oifname "${config.modules.nixos.networking.defaultInterface}" \
          counter masquerade
      ''
    else
      ''
        ${iptables} -D FORWARD -i %i -j ACCEPT
        ${iptables} -D FORWARD -o %i -j ACCEPT
        ${iptables} -t nat -D POSTROUTING \
          -o ${config.modules.nixos.networking.defaultInterface} \
          -j MASQUERADE
      '';

  # Reject traffic not going through WireGuard interface, non-encrypted
  # or non-local
  killSwitchPostUp =
    if config.networking.nftables.enable then
      ''
        ${nft} insert rule inet filter output \
          oifname != "%i" \
          mark != $(${wg} show %i fwmark) \
          fib daddr type != local \
          counter reject
      ''
    else
      ''
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

  killSwitchPreDown =
    if config.networking.nftables.enable then
      ''
        ${nft} delete rule inet filter output \
          oifname != "%i" \
          mark != $(${wg} show %i fwmark) \
          fib daddr type != local \
          counter reject
      ''
    else
      ''
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
          postUp =
            lib.optionals cfg.isVpnServer [ serverPostUp ]
            ++ lib.optionals cfg.useKillSwitch [ killSwitchPostUp ];
          preDown =
            lib.optionals cfg.isVpnServer [ serverPreDown ]
            ++ lib.optionals cfg.useKillSwitch [ killSwitchPreDown ];
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
                  mkClientIp =
                    name:
                    let
                      index = lib.lists.findFirstIndex (elem: elem == name) null clientPeers;
                    in
                    utils.addToAddress cfg.internalIp (index + 1);
                in
                lib.genAttrs clientPeers mkClientIp;

              interfaceConfig =
                if cfg.isVpnServer then
                  ''
                    Address = ${cfg.internalIp}/24
                    ListenPort = ${cfg.listenPort}
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
                    Endpoint = vpn.${config.sops.placeholder."web_domain"}:${cfg.listenPort}
                    AllowedIPs = 0.0.0.0/0
                  '';
            in
            ''
              [Interface]
              ${interfaceConfig}
              PrivateKey = ${config.sops.placeholder."wireguard/home_vpn/${hostName}/private_key"}

              ${peersConfig}
            '';
        };

        networking.wg-quick.interfaces."${cfg.interfaceName}".configFile =
          config.sops.templates."wireguard/${cfg.interfaceName}.conf".path;
      })
      (lib.mkIf (cfg.configFile != null) {
        networking.wg-quick.interfaces."${cfg.interfaceName}".configFile = cfg.configFile;
      })
    ]
  );
}
