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

    environment = {
      etc = {
        "sysctl.d/99-cachyos-settings.conf".source =
          "${cachyos-settings}/lib/sysctl.d/99-cachyos-settings.conf";
        "security/limits.d/20-audio.conf".source =
          "${cachyos-settings}/etc/security/limits.d/20-audio.conf";
      };

      sessionVariables = {
        __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # NVIDIA GPU cache
        MESA_SHADER_CACHE_MAX_SIZE = "12G"; # AMD GPU cache
      };
    };
  };
}
