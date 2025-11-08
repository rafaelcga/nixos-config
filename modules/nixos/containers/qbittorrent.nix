{ config, lib, ... }:
let
  cfg = config.modules.nixos.containers.instances.qbittorrent;
in
lib.mkMerge [
  {
    modules.nixos.containers.instances.qbittorrent = {
      containerPort = 8080;
      containerDataDir = "/var/lib/qBittorrent/";
      behindVpn = true;
    };
  }
  (lib.mkIf cfg.enable {
    containers.qbittorrent = {
      config =
        { pkgs, ... }:
        let
          savePath = "${cfg.containerDataDir}/downloads";
          tempPath = "${savePath}/incomplete";
        in
        {
          services.qbittorrent = {
            enable = true;
            webuiPort = cfg.containerPort;
            profileDir = cfg.containerDataDir;
            openFirewall = true;

            serverConfig = {
              LegalNotice.Accepted = true;

              BitTorrent.Session = {
                DefaultSavePath = savePath;
                Preallocation = true;
                TempPath = tempPath;
                TempPathEnabled = true;
              };

              Preferences = {
                General.Locale = "en";
                Downloads = {
                  SavePath = savePath;
                  TempPath = tempPath;
                };
                WebUI = {
                  AlternativeUIEnabled = true;
                  RootFolder = "${pkgs.vuetorrent}/share/vuetorrent";
                };
              };
            };
          };
        };
    };
  })
]
