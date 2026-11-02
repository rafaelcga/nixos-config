{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20260801-unstable-2026-11-01";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "3ddeeed1ef2f08ecd47a1ca61b067489321d2efa";
    hash = "sha256-4jXI7snprHhPCz/Kzwfu3ii9zbSjZFdCqETxVNDMCXY=";
  };
})
