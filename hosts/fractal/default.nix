{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  modules.nixos = {
    user.name = "rafael";

    boot.loader = "limine";

    audio.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      vendors = [
        "amd"
        "nvidia"
      ];
    };
  };
}
