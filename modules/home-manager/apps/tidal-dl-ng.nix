{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (osConfig.modules.nixos) user;
  cfg = config.modules.home-manager.tidal-dl-ng;

  settingsPath = "${user.home}/.config/tidal-dl-ng/settings.json";

  settingsOpts = {
    options = {
      skip_existing = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Skip download if file already exists.";
      };

      lyrics_embed = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Embed lyrics in audio file, if lyrics are available.";
      };

      lyrics_file = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Save lyrics to separate *.lrc file, if lyrics are available.";
      };

      use_primary_album_artist = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use only the primary album artist for folder paths instead of track artists.";
      };

      video_download = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Allow download of videos.";
      };

      download_delay = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Activate randomized download delay to mimic human behaviour.";
      };

      download_base_path = lib.mkOption {
        type = lib.types.str;
        default = "${user.home}/Music";
        description = "Where to store the downloaded media.";
      };

      quality_audio = lib.mkOption {
        type = lib.types.enum [
          "LOW"
          "HIGH"
          "LOSSLESS"
          "HI_RES_LOSSLESS"
        ];
        default = "HI_RES_LOSSLESS";
        description = ''
          Desired audio download quality: "LOW" (96kbps), "HIGH" (320kbps),
          "LOSSLESS" (16 Bit, 44,1 kHz), "HI_RES_LOSSLESS" (up to 24 Bit, 192 kHz)
        '';
      };

      quality_video = lib.mkOption {
        type = lib.types.enum [
          "360"
          "480"
          "720"
          "1080"
        ];
        default = "1080";
        description = ''
          Desired video download quality: "360", "480", "720", "1080"
        '';
      };

      download_dolby_atmos = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Download Dolby Atmos audio streams if available.";
      };

      format_album = lib.mkOption {
        type = lib.types.str;
        default = "Albums/{album_artist} - {album_title}{album_explicit}/{track_volume_num_optional}{album_track_num}. {artist_name} - {track_title}{album_explicit}";
        description = "Where to download albums and how to name the items.";
      };

      format_playlist = lib.mkOption {
        type = lib.types.str;
        default = "Playlists/{playlist_name}/{list_pos}. {artist_name} - {track_title}";
        description = "Where to download playlists and how to name the items.";
      };

      format_mix = lib.mkOption {
        type = lib.types.str;
        default = "Mix/{mix_name}/{artist_name} - {track_title}";
        description = "Where to download mixes and how to name the items.";
      };

      format_track = lib.mkOption {
        type = lib.types.str;
        default = "Tracks/{artist_name} - {track_title}{track_explicit}";
        description = "Where to download tracks and how to name the items.";
      };

      format_video = lib.mkOption {
        type = lib.types.str;
        default = "Videos/{artist_name} - {track_title}{track_explicit}";
        description = "Where to download videos and how to name the items.";
      };

      video_convert_mp4 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Videos are downloaded as MPEG Transport Stream (TS) files.
          With this option each video will be converted to MP4. FFmpeg
          must be installed.
        '';
      };

      path_binary_ffmpeg = lib.mkOption {
        type = lib.types.str;
        default = "${pkgs.ffmpeg}/bin/ffmpeg";
        description = ''
          Path to FFmpeg binary file (executable). Only necessary if FFmpeg
          not set in $PATH.
        '';
      };

      metadata_cover_dimension = lib.mkOption {
        type = lib.types.enum [
          "320"
          "640"
          "1280"
        ];
        default = "1280";
        description = ''
          The dimensions of the cover image embedded into the track. Possible
          values: "320" (320x320), "640" (640x640), "1280" (1280x1280).
        '';
      };
    };
  };
in
{
  options.modules.home-manager.tidal-dl-ng = {
    enable = lib.mkEnableOption "Enable tidal-dl-ng";

    settings = lib.mkOption {
      type = lib.types.submodule settingsOpts;
      default = { };
      description = "JSON settings at ${settingsPath}";
    };
  };

  config = lib.mkIf cfg.enable { };
}
