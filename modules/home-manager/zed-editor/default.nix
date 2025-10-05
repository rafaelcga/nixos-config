{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.home-manager.zed-editor;
  moduleDir = "${inputs.self}/modules/home-manager/zed-editor";
in
{
  options.modules.home-manager.zed-editor = {
    enable = lib.mkEnableOption "Zed Editor configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      extraPackages = with pkgs; [
        ruff
        basedpyright
        nil
        nixfmt-rfc-style
        nerd-fonts.jetbrains-mono
      ];
    };
    xdg.configFile."zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${moduleDir}/settings.json";
  };
}
