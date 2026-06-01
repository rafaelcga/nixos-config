{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20250501-unstable-2026-05-30";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "b03ccf6ac078ca8242c1d22d00a0f419b26d84e4";
    hash = "sha256-Q42GV6qEbatpakQkw4Kqqg06ZcrrkdKBzfUni5NZtFU=";
  };
})
