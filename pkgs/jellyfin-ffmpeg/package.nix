{
  ffmpeg_7-full,
  jellyfin-ffmpeg,
  fetchFromGitHub,
}:

jellyfin-ffmpeg.overrideAttrs (oldAttrs: rec {
  version = "7.1.3-6";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-ffmpeg";
    rev = "v${version}";
    hash = "sha256-B0B3H2CooNo4b00KbatvfYCIdWXH2jU/WLPXp2KwRwQ=";
  };

  inherit (ffmpeg_7-full) patches;
})
