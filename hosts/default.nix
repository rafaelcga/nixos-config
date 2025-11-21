{
  inputs,
  lib,
  flakeMeta,
  hostName,
  ...
}:
let
  cfg = flakeMeta.hosts.${hostName};
in
{
  imports =
    let
      hostConfigPath = "${inputs.self}/hosts/${hostName}";
      hardwareConfigPath = "${hostConfigPath}/hardware-configuration.nix";
    in
    [ hostConfigPath ] ++ lib.optionals (lib.pathExists hardwareConfigPath) [ hardwareConfigPath ];

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
