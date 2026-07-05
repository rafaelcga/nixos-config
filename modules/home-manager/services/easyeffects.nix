{ config, lib, ... }:
let
  cfg = config.modules.home-manager.easyeffects;
in
{
  options.modules.home-manager.easyeffects = {
    enable = lib.mkEnableOption "Enable EasyEffects with Perfect EQ preset";
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      preset = "perfect-eq-and-mic";
      extraPresets = {
        "perfect-eq-and-mic" = {
          output = {
            blocklist = [ ];
            plugins_order = [ "equalizer" ];
            equalizer = {
              input-gain = -2;
              left = {
                band0 = {
                  frequency = 32;
                  gain = 4;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band1 = {
                  frequency = 64;
                  gain = 2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band2 = {
                  frequency = 125;
                  gain = 1;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band3 = {
                  frequency = 250;
                  gain = 0;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band4 = {
                  frequency = 500;
                  gain = -1;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band5 = {
                  frequency = 1000;
                  gain = -2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band6 = {
                  frequency = 2000;
                  gain = 0;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372449;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band7 = {
                  frequency = 4000;
                  gain = 2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372449;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band8 = {
                  frequency = 8000;
                  gain = 3;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band9 = {
                  frequency = 16000;
                  gain = 3;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
              };
              mode = "IIR";
              num-bands = 10;
              output-gain = 0;
              right = {
                band0 = {
                  frequency = 32;
                  gain = 4;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band1 = {
                  frequency = 64;
                  gain = 2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band2 = {
                  frequency = 125;
                  gain = 1;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band3 = {
                  frequency = 250;
                  gain = 0;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band4 = {
                  frequency = 500;
                  gain = -1;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band5 = {
                  frequency = 1000;
                  gain = -2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band6 = {
                  frequency = 2000;
                  gain = 0;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372449;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band7 = {
                  frequency = 4000;
                  gain = 2;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372449;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band8 = {
                  frequency = 8000;
                  gain = 3;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.5047602375372453;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
                band9 = {
                  frequency = 16000;
                  gain = 3;
                  mode = "RLC (BT)";
                  mute = false;
                  q = 1.504760237537245;
                  slope = "x1";
                  solo = false;
                  type = "Bell";
                };
              };
              split-channels = false;
            };
          };
          input = {
            blocklist = [ ];
            plugins_order = [
              "rnnoise#0"
              "stereo_tools#0"
            ];
            "rnnoise#0" = {
              bypass = false;
              enable-vad = false;
              input-gain = 0;
              model-name = "\"\"";
              output-gain = 0;
              release = 20;
              use-standard-model = true;
              vad-thres = 30;
              wet = 0;
            };
            "stereo_tools#0" = {
              balance-in = 0;
              balance-out = 0;
              bypass = false;
              delay = 0;
              dry = -100;
              input-gain = 0;
              middle-level = 0;
              middle-panorama = 0;
              mode = "LR > L+R (Mono Sum L+R)";
              mutel = false;
              muter = false;
              output-gain = 0;
              phasel = false;
              phaser = false;
              sc-level = 1;
              side-balance = 0;
              side-level = 0;
              softclip = false;
              stereo-base = 0;
              stereo-phase = 0;
              wet = 0;
            };
          };
        };
      };
    };
  };
}
