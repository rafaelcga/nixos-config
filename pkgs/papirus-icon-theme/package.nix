{
  papirus-icon-theme,
  fetchFromGitHub,
}:

# Tracks the upstream default branch, ahead of the nixpkgs release
papirus-icon-theme.overrideAttrs {
  version = "20260801-unstable-2026-11-22";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "626182cfe885b7eb2dbb7bcae5cde6d8d1048f2f";
    hash = "sha256-rDqwXJbvP7dyNfCrC7Z/l5hr/4tnfBX5rTk3cXhlQyk=";
  };
}
