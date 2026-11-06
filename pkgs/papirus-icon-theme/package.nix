{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20260801-unstable-2026-11-04";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "f66c41b7859ecca2a79a2f26a28da481dc01a369";
    hash = "sha256-+0jV1RMocC4RRcayxU8Ny54m4OGOKC5l2oQZ75VTb3Q=";
  };
})
