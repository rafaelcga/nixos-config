{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.crowdsec;
in
{
  options.modules.nixos.crowdsec = {
    enable = lib.mkEnableOption "CrowdSec configuration";
  };

  config = lib.mkIf cfg.enable {
    services.crowdsec.enable = true;
    environment.systemPackages = [ pkgs.crowdsec-firewall-bouncer ];
  };
}
