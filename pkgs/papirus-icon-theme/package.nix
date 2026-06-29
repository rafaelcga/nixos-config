{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20250501-unstable-2026-06-28";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "a1fd8b31af06ecfc3a30cf5dcbbc63f570ed1ac8";
    hash = "sha256-fRNXY7yDEjLCgePhO9mpT+HGteoJS5Pdfi4FipAEAUA=";
  };
})
