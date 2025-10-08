{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.cachy;
  cachyos-settings = pkgs.callPackage ./cachyos-settings/package.nix { };
in
{
  options.modules.nixos.cachy = {
    enable = lib.mkEnableOption "CachyOS optimizations configuration";
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
