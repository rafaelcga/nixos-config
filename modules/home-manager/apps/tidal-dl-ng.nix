{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home-manager.tidal-dl-ng;

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
        default = "~/Music";
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

      metadata_cover_embed = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Embed album cover into file.";
      };

      mark_explicit = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Mark explicit tracks with '🅴' in track title (only applies to metadata).
        '';
      };

      cover_album_file = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Save cover to 'cover.jpg', if an album is downloaded.";
      };

      extract_flac = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Extract FLAC audio tracks from MP4 containers and save them
          as `*.flac` (uses FFmpeg).
        '';
      };

      downloads_simultaneous_per_track_max = lib.mkOption {
        type = lib.types.int;
        default = 20;
        description = "Maximum number of simultaneous chunk downloads per track.";
      };

      download_delay_sec_min = lib.mkOption {
        type = lib.types.float;
        default = 3.0;
        description = "Lower boundary for the calculation of the download delay in seconds.";
      };

      download_delay_sec_max = lib.mkOption {
        type = lib.types.float;
        default = 5.0;
        description = "Upper boundary for the calculation of the download delay in seconds.";
      };

      album_track_num_pad_min = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = ''
          Minimum length of the album track count, will be padded with
          zeroes (0). To disable padding set this to 1.
        '';
      };

      downloads_concurrent_max = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Maximum concurrent number of downloads (threads).";
      };

      symlink_to_track = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          If enabled the tracks of albums, playlists and mixes will be downloaded
          to the track directory but symlinked accordingly.
        '';
      };

      playlist_create = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Creates a '_playlist.m3u8' file for downloaded albums, playlists and mixes.
        '';
      };

      metadata_replay_gain = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Replay gain information will be written to metadata.";
      };

      metadata_write_url = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "URL of the media file will be written to metadata.";
      };

      window_x = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "X-Coordinate of saved window location.";
      };

      window_y = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "Y-Coordinate of saved window location.";
      };

      window_w = lib.mkOption {
        type = lib.types.int;
        default = 1200;
        description = "Width of saved window size.";
      };

      window_h = lib.mkOption {
        type = lib.types.int;
        default = 800;
        description = "Height of saved window size.";
      };

      metadata_delimiter_artist = lib.mkOption {
        type = lib.types.str;
        default = ", ";
        description = "Metadata tag delimiter for multiple artists. Default: ', '";
      };

      metadata_delimiter_album_artist = lib.mkOption {
        type = lib.types.str;
        default = ", ";
        description = "Metadata tag delimiter for multiple album artists. Default: ', '";
      };

      filename_delimiter_artist = lib.mkOption {
        type = lib.types.str;
        default = ", ";
        description = "Filename delimiter for multiple artists. Default: ', '";
      };

      filename_delimiter_album_artist = lib.mkOption {
        type = lib.types.str;
        default = ", ";
        description = "Filename delimiter for multiple album artists. Default: ', '";
      };

      metadata_target_upc = lib.mkOption {
        type = lib.types.enum [
          "UPC"
          "BARCODE"
          "EAN"
        ];
        default = "UPC";
        description = ''
          Select the target metadata tag ('UPC', 'BARCODE', 'EAN') where to
          write the UPC information to. Default: 'UPC'.
        '';
      };

      api_rate_limit_batch_size = lib.mkOption {
        type = lib.types.int;
        default = 20;
        description = ''
          Number of albums to process before applying rate limit delay (tweaking variable).
        '';
      };

      api_rate_limit_delay_sec = lib.mkOption {
        type = lib.types.float;
        default = 3.0;
        description = ''
          Delay in seconds between batches to avoid API rate limiting (tweaking variable).
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
      description = ''
        Settings to be saved as JSON at ~/.config/tidal_dl_ng/settings.json
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.local.tidal-dl-ng ];

    systemd.user.services.generate-tidal-dl-ng-settings = {
      Unit.Description = "Generates tidal-dl-ng writable settings.json from Nix config";
      Install.WantedBy = [ "default.target" ];
      Service =
        let
          bash = "${pkgs.bash}/bin/bash";
          mkdir = "${pkgs.coreutils}/bin/mkdir";
          jq = "${pkgs.jq}/bin/jq";
          escapedJsonString = lib.escapeShellArg (builtins.toJSON cfg.settings);

          writeJsonScript = pkgs.writeScriptBin "generate-tidal-dl-ng-settings-script.sh" ''
            #!${bash}
            set -euo pipefail

            CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/tidal_dl_ng"
            ${mkdir} -p "$CONFIG_DIR"

            echo ${escapedJsonString} | ${jq} "." >"$CONFIG_DIR/settings.json"
          '';
        in
        {
          Type = "oneshot";
          ExecStart = "${writeJsonScript}/bin/generate-tidal-dl-ng-settings-script.sh";
        };
    };
  };
}
