{ config, lib, ... }:
let
  cfg = config.modules.nixos.steam;
in
{
  options.modules.nixos.steam = {
    enable = lib.mkEnableOption "Steam configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
