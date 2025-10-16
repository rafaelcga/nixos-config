{ config, ... }:
let
  inherit (config.system) stateVersion;
in
{
  autoStart = true;
  privateNetwork = true;
  hostAddress = "192.168.100.10";
  hostAddress6 = "fc00::1";

  config = {
    system = { inherit stateVersion; };
  };
}
