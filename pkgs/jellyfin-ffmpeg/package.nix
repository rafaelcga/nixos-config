{
  ffmpeg_7-full,
  jellyfin-ffmpeg,
  fetchFromGitHub,
}:

jellyfin-ffmpeg.overrideAttrs (oldAttrs: rec {
  version = "7.1.3-5";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-ffmpeg";
    rev = "v${version}";
    hash = "sha256-8cYjrENpLmlZ75I8TpXTuf6juTooCaRjTdPVfDGfpKo=";
  };

  inherit (ffmpeg_7-full) patches;
})
