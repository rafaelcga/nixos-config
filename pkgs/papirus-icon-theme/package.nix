{
  papirus-icon-theme,
  fetchFromGitHub,
}:

# Tracks the upstream default branch, ahead of the nixpkgs release
papirus-icon-theme.overrideAttrs {
  version = "20260801-unstable-2026-11-09";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "33d971eb2d0c8454bac58246687de78e58f960c8";
    hash = "sha256-fCa4Y0pMR0hlfwtsXpzv3anWz+1m0WOc+ID/Lx0BRLQ=";
  };
}
