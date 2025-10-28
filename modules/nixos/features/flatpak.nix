{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.modules.nixos) user;
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

    systemd.services.user-icons-fonts-flatpak = {
      description = "Makes icons and fonts in the user's directory available for Flatpaks";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.name;
        Group = user.group;
      };
      script = ''
        set -euo pipefail

        ${pkgs.flatpak}/bin/flatpak --user override --filesystem="$HOME/.local/share/fonts:ro"
        ${pkgs.flatpak}/bin/flatpak --user override --filesystem="$HOME/.icons:ro"
        ${pkgs.flatpak}/bin/flatpak --user override --filesystem="/nix/store:ro"
      '';
    };
  };
}
