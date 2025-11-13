{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.wireguard;

  iptables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
  nft = "${pkgs.nftables}/bin/nft";
  wg = "${pkgs.wireguard-tools}/bin/wg";

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
      type = lib.types.str;
      description = "Path to the WireGuard configuration file";
    };

    isVpnServer = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether host acts as WireGuard server";
    };

    useKillSwitch = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Setup kill-switch for WireGuard interface";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wg-quick.interfaces = {
      "${cfg.interfaceName}" = {
        inherit (cfg) configFile;
        postUp =
          lib.optionals cfg.isVpnServer [ serverPostUp ]
          ++ lib.optionals cfg.useKillSwitch [ killSwitchPostUp ];
        preDown =
          lib.optionals cfg.isVpnServer [ serverPreDown ]
          ++ lib.optionals cfg.useKillSwitch [ killSwitchPreDown ];
      };
    };
  };
}
