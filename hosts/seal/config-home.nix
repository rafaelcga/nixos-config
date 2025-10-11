{ ... }:
{
  imports = [
    ../../modules/common
    ../../modules/home-manager
    ./configs/home-manager
  ];

  modules = {
    home-manager = {
    };
  };
}
