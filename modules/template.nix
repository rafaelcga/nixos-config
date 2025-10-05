{ config, lib, ... }:
let
  cfg = config.modules.type.name;
in
{
  options.modules.type.name = {
    enable = lib.mkEnableOption "";
  };

  config = lib.mkIf cfg.enable { };
}
