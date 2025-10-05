{ ... }:
{
  imports = [
    ../../modules/home-manager
    ../../modules/nixos/catppuccin
    ./configs/home-manager
  ];

  modules.home-manager = {
    zed-editor.enable = true;
  };
  modules.nixos.catppuccin.enable = true;
}
