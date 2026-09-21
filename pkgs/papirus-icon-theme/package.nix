{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20260801-unstable-2026-09-21";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "bf539287ef5dc18529424a02cccee76175920a6f";
    hash = "sha256-X1iD/1cPRU0lOkMu8nyUaGJTWOzyOiB6i+nlAYRF66I=";
  };
})
