{ flakeMeta, hostName, ... }:
let
  cfg = flakeMeta.hosts.${hostName};
in
{
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
