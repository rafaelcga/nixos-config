{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.modules.nixos) user;
  cfg = config.modules.home-manager.tidal-dl-ng;

  settingsPath = "${user.home}/.config/tidal-dl-ng/settings.json";

  settingsOpts = {
    options = {
      skip_existing = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Skip download if file already exists.";
      };

      lyrics_embed = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Embed lyrics in audio file, if lyrics are available.";
      };

      lyrics_file = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Save lyrics to separate *.lrc file, if lyrics are available.";
      };
    };
  };
in
{
  options.modules.home-manager.tidal-dl-ng = {
    enable = lib.mkEnableOption "Enable tidal-dl-ng";

    settings = lib.mkOption {
      type = lib.types.submodule settingsOpts;
      default = { };
      description = "JSON settings at ${settingsPath}";
    };
  };

  config = lib.mkIf cfg.enable { };
}
