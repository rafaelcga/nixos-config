{ config, lib, ... }:
let
  cfg = config.modules.nixos.audio;
  bufferSize = 128;
  bluetoothEnabled = config.hardware.bluetooth.enable;
in
{
  options.modules.nixos.audio = {
    enable = lib.mkEnableOption "PipeWire and audio configuration";
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
      wireplumber.extraConfig.bluetoothEnhancements = lib.mkIf bluetoothEnabled {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
        };
      };
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = bufferSize;
          "default.clock.min-quantum" = bufferSize;
          "default.clock.max-quantum" = bufferSize;
        };
      };
    };
  };
}
