{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.flatpak;
  user = config.users.users.${userName};
in
{
  options.modules.nixos.flatpak = {
    enable = lib.mkEnableOption "Enable Flatpak support and add Flathub";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    environment.sessionVariables = {
      GSK_RENDERER = "gl"; # fixes graphical flatpak bug under Wayland
      QT_QPA_PLATFORM = "xcb"; # Telegram crashes with NVIDIA+Wayland
    };

    systemd.services =
      let
        flatpak = lib.getExe pkgs.flatpak;
      in
      {
        add-flathub-repo = rec {
          description = "Adds Flathub repository";
          after = [ "network-online.target" ];
          wants = after;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            Restart = "on-failure";
            RestartSec = "10s";
            ExecStart = ''
              ${flatpak} remote-add --if-not-exists \
                flathub https://dl.flathub.org/repo/flathub.flatpakrepo
            '';
          };
        };

        user-icons-fonts-flatpak = {
          description = "Makes icons and fonts in the user's directory available for Flatpaks";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = user.name;
            Group = user.group;
            ExecStart = [
              "${flatpak} --user override --filesystem=\"${user.home}/.local/share/fonts:ro\""
              "${flatpak} --user override --filesystem=\"${user.home}/.local/share/icons:ro\""
              "${flatpak} --user override --filesystem=\"/nix/store:ro\""
            ];
          };
        };
      };
  };
}
