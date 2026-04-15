{
  fetchFromGitHub,
  catppuccin-papirus-folders,
  papirus-icon-theme,
  flavor ? "mocha",
  accent ? "blue",
}:

papirus-icon-theme.overrideAttrs (oldAttrs: {
  version = "0-unstable-2024-06-08";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "papirus-folders";
    rev = "f83671d17ea67e335b34f8028a7e6d78bca735d7";
    sha256 = "sha256-FiZdwzsaMhS+5EYTcVU1LVax2H1FidQw97xZklNH2R4=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons
    cp -r --no-preserve=mode ${papirus-icon-theme}/share/icons/Papirus* $out/share/icons
    cp -r src/* $out/share/icons/Papirus

    for theme in $out/share/icons/*; do
      papirus-folders -t $theme -o -C cat-${flavor}-${accent}
      gtk-update-icon-cache --force $theme
    done

    runHook postInstall
  '';

  inherit (catppuccin-papirus-folders) meta;
})
