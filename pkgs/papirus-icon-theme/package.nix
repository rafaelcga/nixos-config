{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20260801-unstable-2026-08-01";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "5f8b701d7521e27b4859d7e4f9b0da4c423c036c";
    hash = "sha256-ZmZefBzwtHVV49BUWgHihSnwGQbKFek3+HpUjjXJ36c=";
  };
})
