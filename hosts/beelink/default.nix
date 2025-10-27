{
  imports = [
    ./disko.nix
  ];

  modules.nixos = {
    zram.enable = true;
    ssh.enable = true;

    graphics = {
      enable = true;
      vendors = [ "intel" ];
    };

    crowdsec.enable = true;
  };
}
