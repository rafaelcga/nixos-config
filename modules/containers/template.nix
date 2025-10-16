{ config, lib, ... }:
let
  cfg = config.modules.containers.name;
in
{
  options.modules.containers.name = {
    enable = lib.mkEnableOption "";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Container name";
    };
    localAddress = lib.mkOption {
      type = lib.types.str;
      description = "Local container IPv4 address";
    };
    localAddress6 = lib.mkOption {
      type = lib.types.str;
      description = "Local container IPv6 address";
    };
  };

  config = lib.mkIf cfg.enable {
    containers.${cfg.name} = { }; # TODO
  };
}
