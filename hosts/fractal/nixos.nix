{ ... }:
{
  imports = [
    ../../modules/nixos
    ./configs/nixos
  ];

  nixosModules = {
    boot = {
      enable = true;
      loader = "limine";
    };
  };
}
