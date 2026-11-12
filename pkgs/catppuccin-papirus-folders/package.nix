{
  catppuccin-papirus-folders,
  papirus-icon-theme,
  flavor ? "mocha",
  accent ? "blue",
}:

# Built on top of (our) papirus-icon-theme rather than nixpkgs' own package, which
# drops the icon caches and the breeze/hicolor links that Papirus inherits from.
# The catppuccin source itself is tracked by nixpkgs.
papirus-icon-theme.overrideAttrs {
  pname = "catppuccin-papirus-folders";
  inherit (catppuccin-papirus-folders) version src meta;

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
}
