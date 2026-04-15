{
  jellyfin-ffmpeg,
  fetchFromGitHub,
}:

jellyfin-ffmpeg.overrideAttrs (finalAttrs: rec {
  version = "7.1.3-5";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-ffmpeg";
    rev = "v${version}";
    hash = "sha256-8cYjrENpLmlZ75I8TpXTuf6juTooCaRjTdPVfDGfpKo=";
  };
})
