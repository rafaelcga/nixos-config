{
  config,
  lib,
  pkgs,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.fonts;
  user = config.users.users.${userName};
in
{
  options.modules.nixos.fonts = {
    enable = lib.mkEnableOption "Install a default set of fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        corefonts
        vista-fonts
        liberation_ttf
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji
        nerd-fonts.jetbrains-mono
        nerd-fonts.zed-mono
      ];
    };

    systemd.services.copy-link-fonts = {
      description = "Copies system fonts to user's home";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = user.name;
        Group = user.group;
        ExecStart =
          let
            localFontDir = "${user.home}/.local/share/fonts";
            pastLocalFontDir = "${user.home}/.fonts";
          in
          lib.getExe (
            pkgs.writeShellApplication {
              name = "copy-link-fonts-script";
              runtimeInputs = with pkgs; [ coreutils ];
              text = ''
                rm -rf "${localFontDir}"
                rm -rf "${pastLocalFontDir}"

                mkdir -p "${localFontDir}"
                cp -rL "/run/current-system/sw/share/X11/fonts/." "${localFontDir}"
                chmod -R 755 "${localFontDir}"

                ln -s "${localFontDir}" "${pastLocalFontDir}"
              '';
            }
          );
      };
    };
  };
}
