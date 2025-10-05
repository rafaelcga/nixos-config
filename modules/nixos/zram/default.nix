{ config, lib, ... }:
let
  cfg = config.modules.nixos.zram;
in
{
  options.modules.nixos.zram = {
    enable = lib.mkEnableOption "ZRAM swap configuration";
  };

  config = lib.mkIf cfg.enable {
    # github:CachyOS/CachyOS-Settings/blob/master/usr/lib/systemd/zram-generator.conf
    zramSwap = {
      enable = true;
      memoryPercent = 100; # amount of ZRAM == system RAM
      priority = 100;
      algorithm = "zstd lz4 (type=huge)";
    };
  };
}
