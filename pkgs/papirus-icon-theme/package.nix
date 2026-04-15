{
  papirus-icon-theme,
  fetchFromGitHub,
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "20250501-unstable-2026-04-02";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-icon-theme";
    rev = "c5a48381fce7fda86fb9067fd7816f7de11c0aeb";
    hash = "sha256-bqSE3kp6JEnjBrEbsVhL7Q9u4RHu+a/QLTFAuRJHoE0=";
  };
})
