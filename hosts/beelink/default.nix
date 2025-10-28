{
  imports = [
    ./disko.nix
  ];

  modules.nixos = {
    # System
    zram.enable = true;
    ssh.enable = true;
    # Hardware
    graphics = {
      enable = true;
      vendors = [ "intel" ];
    };
    # Services
    caddy.enable = true;
    crowdsec.enable = true;
  };
}
