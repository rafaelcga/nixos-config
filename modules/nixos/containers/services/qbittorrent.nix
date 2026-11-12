{
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.containers.services.qbittorrent;
  inherit (config.modules.nixos.containers) user;

  # Replaced at service start with the PBKDF2 hash from sops
  passwordSecret = config.sops.secrets."qbittorrent/password_hash".path;
  passwordPlaceholder = "@QBITTORRENT_PASSWORD_HASH@";
in
lib.mkMerge [
  {
    modules.nixos.containers.services.qbittorrent = {
      uid = 6;
      containerPort = 8080;
      dataDir = "/var/lib/qBittorrent";
      behindVpn = true;
      excludeFromBackup = [ "downloads/**" ];
    };
  }
  (lib.mkIf cfg.enable {
    sops.secrets."qbittorrent/password_hash".owner = user.name;

    containers.qbittorrent = {
      bindMounts.${passwordSecret}.isReadOnly = true;

      config =
        { config, pkgs, ... }:
        let
          savePath = "${cfg.dataDir}/downloads";
          tempPath = "${savePath}/incomplete";
          configFile = "${config.services.qbittorrent.profileDir}/qBittorrent/config/qBittorrent.conf";
        in
        {
          # Runs after the module has installed qBittorrent.conf from `serverConfig`
          systemd.services.qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [
            (pkgs.writeShellScript "qbittorrent-set-password" ''
              hash="$(< "${passwordSecret}")"
              ${lib.getExe pkgs.gnused} -i "s|${passwordPlaceholder}|$hash|" "${configFile}"
            '')
          ];

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
                  Password_PBKDF2 = passwordPlaceholder;
                  HostHeaderValidation = false;
                  CSRFProtection = false;
                };
              };
            };
          };
        };
    };
  })
]
