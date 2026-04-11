{
  inputs,
  config,
  lib,
  userName,
  ...
}:
let
  cfg = config.modules.nixos.audio;
in
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  options.modules.nixos.audio = {
    enable = lib.mkEnableOption "Enable audio through PipeWire";

    sampleRate = lib.mkOption {
      type = lib.types.int;
      default = 48000;
      description = "Audio sample rate in Hz";
    };

    bufferSize = lib.mkOption {
      type = lib.types.int;
      default = 256;
      description = "Audio buffer size (number of sample)";
    };
  };

  config = lib.mkIf cfg.enable {
    musnix.enable = true;
    security.rtkit.enable = true;
    users.users.${userName}.extraGroups = [ "audio" ];

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      wireplumber.extraConfig.bluetoothEnhancements = lib.mkIf config.hardware.bluetooth.enable {
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

      extraConfig = {
        pipewire."92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = cfg.sampleRate;
            "default.clock.quantum" = cfg.bufferSize;
            "default.clock.min-quantum" = cfg.bufferSize;
            "default.clock.max-quantum" = cfg.bufferSize;
          };
        };
        pipewire-pulse."92-low-latency" =
          let
            latency = "${toString cfg.bufferSize}/${toString cfg.sampleRate}";
          in
          {
            context.modules = [
              {
                name = "libpipewire-module-protocol-pulse";
                args = {
                  pulse.min.req = latency;
                  pulse.default.req = latency;
                  pulse.max.req = latency;
                  pulse.min.quantum = latency;
                  pulse.max.quantum = latency;
                };
              }
            ];
            stream.properties = {
              node.latency = latency;
              resample.quality = 1;
            };
          };
      };
    };
  };
}
