{
  inputs,
  lib,
  flakeMeta,
  hostName,
  ...
}:
{
  imports =
    let
      hostConfigPath = "${inputs.self}/hosts/${hostName}";
      hardwareConfigPath = "${hostConfigPath}/hardware-configuration.nix";
    in
    [ hostConfigPath ] ++ lib.optionals (lib.pathExists hardwareConfigPath) [ hardwareConfigPath ];

  networking.hostName = hostName;

  system.stateVersion = flakeMeta.stateVersion;

  nixpkgs = {
    hostPlatform = flakeMeta.hosts.${hostName}.system;
    config.allowUnfree = true;
  };

  modules.nixos.home-vpn = {
    enable = true;
    serverHostName = "beelink";
  };
}
