{ ... }:
{
  imports = [
    ../../modules/nixos
    ./configs/nixos
  ];

  modules.nixos = {
    boot = {
      enable = true;
      loader = "limine";
    };
    i18n.enable = true;
  };
}
