{ config, lib, ... }:
let
  cfg = config.modules.nixos.audio;
  usesBluetooth = config.hardware.bluetooth.enable;
in
{
  options.modules.nixos.audio = {
    enable = lib.mkEnableOption "Enable audio through PipeWire";
    sampleRate = lib.mkOption {
      type = lib.types.int;
      default = 48000;
      description = "Audio sample rate in Hz";
    };
    bufferSize = lib.mkOption {
      type = lib.types.int;
      default = 128;
      description = "Audio buffer size (number of sample)";
    };
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
      wireplumber.extraConfig.bluetoothEnhancements = lib.mkIf usesBluetooth {
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
          "default.clock.rate" = cfg.sampleRate;
          "default.clock.quantum" = cfg.bufferSize;
          "default.clock.min-quantum" = cfg.bufferSize;
          "default.clock.max-quantum" = cfg.bufferSize;
        };
      };
    };
  };
}
