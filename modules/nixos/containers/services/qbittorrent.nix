{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.qbittorrent;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.qbittorrent = {
      containerPort = 8080;
      containerDataDir = "/var/lib/qBittorrent/";
      # behindVpn = true;
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
            user = cfg.user.name;
            inherit (cfg.user) group;

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
                  Username = userName;
                  Password_PBKDF2 = "@ByteArray(4quLRWi4zO+tAPClYLWbaw==:P5PWcrBP/z/uZhVGn18vCK4ryKT/xvL4nAFxx/qlUPX2/9DWF7Q0L0jZR7Ii4863PH6YQj8s8d7U0Otjuuv2+Q==)";
                  HostHeaderValidation = false;
                  CSRFProtection = false;
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
