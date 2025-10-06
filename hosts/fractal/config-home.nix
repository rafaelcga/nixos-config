{ ... }:
{
  imports = [
    ../../modules/home-manager
    ./configs/home-manager
  ];

  modules.home-manager = {
    zed-editor.enable = true;
    catppuccin.enable = true;
    programs.enable = true;
    chrome.enable = true;
  };
}
