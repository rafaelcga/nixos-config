{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.modules.nixos) user;
  cfg = config.modules.home-manager.yt-dlp;

  settings = {
    # Output
    output = "${user.home}/Videos/%(playlist)s/%(title)s.%(ext)s";
    # Format
    format = "bv*+ba";
    format-sort = "lang,res,quality,+vcodec:av1,acodec";
    extractor-args = "youtube:lang=en";
    # Download options
    throttled-rate = "1M";
    cookies-from-browser = "firefox";
    # Playlist options
    ignore-errors = true;
    continue = true;
    no-overwrites = true;
    download-archive = "${user.home}/.cache/yt-dlp/downloads.txt";
    # Post-processing options
    remux-video = "mkv";
    embed-chapters = true;
    embed-info-json = true;
    # Subs options
    embed-subs = true;
    sub-langs = "'en.*,es',-live_chat";
    convert-subs = "srt";
    # SponsorBlock
    sponsorblock-remove = "sponsor";
  };
in
{
  options.modules.home-manager.yt-dlp = {
    enable = lib.mkEnableOption "Enable yt-dlp";
  };

  config = lib.mkIf cfg.enable {
    programs.yt-dlp = {
      inherit settings;
      enable = true;
    };
  };
}
