{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.qbittorrent;
  inherit (config.modules.nixos.containers) user;
in
lib.mkMerge [
  {
    modules.nixos.containers.services.qbittorrent = {
      containerPort = 8080;
      dataDir = "/var/lib/qBittorrent";
      behindVpn = true;
    };
  }
  (lib.mkIf cfg.enable {
    containers.qbittorrent = {
      config =
        { pkgs, ... }:
        let
          savePath = "${cfg.dataDir}/downloads";
          tempPath = "${savePath}/incomplete";
        in
        {
          services.qbittorrent = {
            enable = true;
            user = user.name;
            inherit (user) group;

            webuiPort = cfg.containerPort;
            profileDir = cfg.dataDir;
            openFirewall = true;

            serverConfig = {
              LegalNotice.Accepted = true;

              BitTorrent.Session = {
                AlternativeGlobalDLSpeedLimit = 0;
                AlternativeGlobalUPSpeedLimit = 0;
                QueueingSystemEnabled = true;
                IgnoreSlowTorrentsForQueueing = true;
                SlowTorrentsDownloadRate = 100;
                SlowTorrentsUploadRate = 100;
                AnonymousModeEnabled = true;
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
