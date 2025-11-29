{
  inputs,
  config,
  lib,
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
      containerPort = 8096;
      dataDir = "/var/lib/jellyfin";
    };
  }
  (lib.mkIf cfg.enable {
    containers.jellyfin = {
      config =
        { config, pkgs, ... }:
        {
          imports = [ "${inputs.self}/modules/nixos/hardware/graphics.nix" ];

          _module.args.userName = user.name;

          modules.nixos.graphics = lib.mkIf cfg.gpuPassthrough configModules.graphics;

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
            jellyfin-ffmpeg
          ];

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
      };
    };
  })
]
