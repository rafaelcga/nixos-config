{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.jellyfin;
  inherit (config.modules.nixos.containers) user;
  configModules = config.modules.nixos;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.jellyfin = {
      uid = 4;
      containerPort = 8096;
      dataDir = "/var/lib/jellyfin";
      gpuPassthrough = lib.mkDefault true;
    };
  }
  (lib.mkIf cfg.enable {
    containers.jellyfin = {
      config =
        { config, ... }:
        {
          services.jellyfin = {
            enable = true;
            user = user.name;
            inherit (user) group;
            openFirewall = true;

            inherit (cfg) dataDir;
            configDir = "${cfg.dataDir}/config";
            cacheDir = "${cfg.dataDir}/cache";
            logDir = "${cfg.dataDir}/log";
          };

          environment.systemPackages = with pkgs; [
            jellyfin
            jellyfin-web
            local.jellyfin-ffmpeg
          ];

          systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME =
            config.environment.sessionVariables.LIBVA_DRIVER_NAME;

          systemd.tmpfiles.settings =
            let
              inherit (config.services.jellyfin) configDir;
            in
            {
              "10-generate-jellyfin-config" = {
                "${configDir}".d = {
                  user = user.name;
                  inherit (user) group;
                  mode = "750";
                };
                "${configDir}/branding.xml"."f+" = {
                  user = user.name;
                  inherit (user) group;
                  mode = "640";
                  argument =
                    let
                      inherit (configModules.catppuccin) flavor accent;
                      customCss = ''
                        @import url('https://jellyfin.catppuccin.com/theme.css');
                        @import url('https://jellyfin.catppuccin.com/catppuccin-${flavor}.css');
                        :root {
                            --main-color: var(--${accent});
                        }
                      '';
                    in
                    ''
                      <?xml version="1.0" encoding="utf-8"?>
                      <BrandingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
                        <LoginDisclaimer />
                        <CustomCss>${customCss}</CustomCss>
                        <SplashscreenEnabled>false</SplashscreenEnabled>
                      </BrandingOptions>
                    '';
                };
              };
            };
        };
    };

    modules.nixos.caddy = lib.mkIf configModules.caddy.enable {
      virtualHosts.jellyfin = {
        originHost = cfg.address;
        originPort = cfg.containerPort;
        extraConfig = ''
          header Content-Security-Policy "default-src https: data: blob: http://image.tmdb.org; style-src 'self' 'unsafe-inline' https://jellyfin.catppuccin.com; script-src 'self' 'unsafe-inline' https://www.gstatic.com/cv/js/sender/v1/cast_sender.js https://www.youtube.com blob:; worker-src 'self' blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'self'"
          header -X-Frame-Options
        '';
      };
    };
  })
]
