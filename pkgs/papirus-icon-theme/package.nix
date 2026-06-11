{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20250501-unstable-2026-06-09";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "f202823e4721d050c87160688a33a223439b2a5f";
    hash = "sha256-ykI21VSd6vAu5MZ0gnwxKKU87bimXQUEA4AQa80jY+c=";
  };
})
