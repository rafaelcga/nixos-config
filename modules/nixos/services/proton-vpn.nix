{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.proton-vpn;

  iptables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
  nft = "${pkgs.nftables}/bin/nft";
  wg = "${pkgs.wireguard-tools}/bin/wg";

  postUpScript =
    if config.networking.nftables.enable then
      ''
        #!/bin/bash

        set -euo pipefail

        ${nft} insert rule inet filter output \
          oifname != "%i" \
          mark != $(${wg} show %i fwmark) \
          fib daddr type != local \
          counter reject
      ''
    else
      ''
        #!/bin/bash

        set -euo pipefail

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
  killSwitchPostUp = pkgs.writeScriptBin "killswitch-up" postUpScript;

  PreDownScript =
    if config.networking.nftables.enable then
      ''
        #!/bin/bash

        set -euo pipefail

        ${nft} delete rule inet filter output \
          oifname != "%i" \
          mark != $(${wg} show %i fwmark) \
          fib daddr type != local \
          counter reject
      ''
    else
      ''
        #!/bin/bash

        set -euo pipefail

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
  killSwitchPreDown = pkgs.writeScriptBin "killswitch-down" PreDownScript;
in
{
  options.modules.nixos.proton-vpn = {
    enable = lib.mkEnableOption "Enables Proton VPN through WireGuard";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the WireGuard interface";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      secrets = {
        "proton/wireguard/public_key" = { };
        "proton/wireguard/private_key" = { };
        "proton/wireguard/endpoint" = { };
      };
      templates."${cfg.interfaceName}.conf".content = ''
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
      "${cfg.interfaceName}" = {
        configFile = config.templates."${cfg.interfaceName}.conf".path;
        postUp = "${killSwitchPostUp}/bin/killswitch-up";
        preDown = "${killSwitchPreDown}/bin/killswitch-down";
      };
    };
  };
}
