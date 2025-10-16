{ inputs, ... }:
{
  imports = [
    "${inputs.self}/modules/common"
    "${inputs.self}/modules/home-manager"
    ./configs/home-manager
  ];

  modules = {
    home-manager = {
    };
  };
}
