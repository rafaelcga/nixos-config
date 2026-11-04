{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20260801-unstable-2026-11-01";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "072a55a432f075acd4932bb4aab6a154746b784d";
    hash = "sha256-THZqhybT4nu77JH5qxd2/5iHL2xgc5/nHAl17tJiuoo=";
  };
})
