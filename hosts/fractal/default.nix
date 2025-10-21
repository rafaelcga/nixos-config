{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  modules.nixos = {
    user.name = "rafael";
  };
}
