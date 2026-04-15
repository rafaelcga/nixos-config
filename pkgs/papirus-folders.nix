{
  papirus-folders,
  fetchFromGitHub,
}:

papirus-folders.overrideAttrs (oldAttrs: rec {
  version = "1.14.0";

  src = fetchFromGitHub {
    owner = "PapirusDevelopmentTeam";
    repo = "papirus-folders";
    rev = "v${version}";
    sha256 = "sha256-pkzYhE4dNqyl5TvXQqs915QzwZwsXtdAQ+4B29oe9LA=";
  };
})
