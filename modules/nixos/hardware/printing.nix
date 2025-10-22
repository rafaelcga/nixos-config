{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.printing;
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "Enable printing support";
  };

  config = lib.mkIf cfg.enable {
    services = {
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };

      printing = {
        enable = true;
        drivers = with pkgs; [
          cups-filters
          cups-browsed
        ];
      };
    };
  };
}
