{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20250501-unstable-2026-07-22";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "1b926382757f685622901f9c17a9abce66415ff0";
    hash = "sha256-a0TN+O14iTaUlviad0oN4A+XF9abYGo5/45ydafG8+k=";
  };
})
