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
      zed-editor.enable = true;
      programs.enable = true;
      papirus.enable = true;
      cursor-theme.enable = true;
    };
  };
}
