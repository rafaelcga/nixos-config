{
  inputs,
  lib,
  flakeMeta,
  hostName,
  ...
}:
let
  cfg = flakeMeta.hosts.${hostName};
  hardwareConfigPath = "${inputs.self}/hosts/${hostName}/hardware-configuration.nix";
in
{
  imports = [
    "${inputs.self}/hosts/${hostName}"
  ]
  ++ lib.optionals (lib.pathExists hardwareConfigPath) [ hardwareConfigPath ];

  networking.hostName = hostName;

  system.stateVersion = cfg.stateVersion;

  nixpkgs = {
    hostPlatform = cfg.system;
    config.allowUnfree = true;
  };

  modules.nixos.home-vpn = {
    enable = true;
    serverHostName = "beelink";
  };
}
