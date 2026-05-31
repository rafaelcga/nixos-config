{
  ffmpeg_7-full,
  jellyfin-ffmpeg,
  fetchFromGitHub,
}:

jellyfin-ffmpeg.overrideAttrs (oldAttrs: rec {
  version = "8.1.1-1";

  src = fetchFromGitHub {
    owner = "jellyfin";
    repo = "jellyfin-ffmpeg";
    rev = "v${version}";
    hash = "sha256-ITTnqMDQFabzE+LOcM4Mft7Ctmxut2g04JAUWt1JoHo=";
  };

  inherit (ffmpeg_7-full) patches;
})
