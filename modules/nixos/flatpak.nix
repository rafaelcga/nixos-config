{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.flatpak;
in
{
  options.modules.nixos.flatpak = {
    enable = lib.mkEnableOption "Enable Flatpak support and add Flathub";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    systemd.services.add-flathub-repo = {
      description = "Adds Flathub repository";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
