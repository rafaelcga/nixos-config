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

    caddy.enable = true;
    crowdsec.enable = true;
  };
}
