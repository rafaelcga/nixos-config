{ ... }:
{
  imports = [
    ../../modules/common
    ../../modules/home-manager
    ./configs/home-manager
  ];

  modules = {
    common = {
      theme.enable = true;
    };
    home-manager = {
      # Desktop environment
      plasma.enable = true;
      papirus.enable = true;
      cursor-theme.enable = true;
      # Programs
      zed-editor.enable = true;
      ghostty.enable = true;
    };
  };
}
