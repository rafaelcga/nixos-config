{ ... }:
{
  imports = [
    ../../modules/nixos/theme
    ../../modules/home-manager
    ./configs/home-manager
  ];

  modules = {
    home-manager = {
      zed-editor.enable = true;
      programs.enable = true;
      chrome.enable = true;
      icons.enable = true;
    };
    nixos = {
      theme.enable = true;
    };
  };
}
