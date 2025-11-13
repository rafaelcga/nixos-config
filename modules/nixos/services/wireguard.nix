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
        # Reject traffic not going through WireGuard interface, non-encrypted
        # or non-local
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
        # Delete post-up rule
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
        postUp = lib.optionals cfg.useKillSwitch [ killSwitchPostUp ];
        preDown = lib.optionals cfg.useKillSwitch [ killSwitchPreDown ];
      };
    };
  };
}
