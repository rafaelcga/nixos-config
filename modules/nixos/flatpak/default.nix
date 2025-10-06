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
    enable = lib.mkEnableOption "Flatpak configuration";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    systemd.services.flathub-repo = {
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.flatpak ];
      script = ''
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
