{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.local) cachyos-settings;
  cfg = config.modules.nixos.cachyos-settings;
in
{
  imports = [ ];

  options.modules.nixos.cachyos-settings = {
    enable = lib.mkEnableOption "Enable CachyOS optimizations";
  };

  config = lib.mkIf cfg.enable {
    services = {
      udev = {
        enable = true;
        packages = [ cachyos-settings ];
      };
      ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    };
    environment.etc = {
      "sysctl.d/99-cachyos-settings.conf".source =
        "${cachyos-settings}/usr/lib/sysctl.d/99-cachyos-settings.conf";
      "security/limits.d/20-audio.conf".source =
        "${cachyos-settings}/etc/security/limits.d/20-audio.conf";
    };
  };
}
