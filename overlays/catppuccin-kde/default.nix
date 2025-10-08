{ config, lib, ... }:
let
  upperFlavor = lib.local.capitalizeFirst config.catppuccin.flavor or "";
  upperAccent = lib.local.capitalizeFirst config.catppuccin.accent or "";
  nixosLogoPath = ../../resources/icons/nix-snowflake-rainbow-pastel.png;
in
(final: prev: {
  catppuccin-kde =
    (prev.catppuccin-kde.override {
      flavour = [ config.catppuccin.flavor ];
      accents = [ config.catppuccin.accent ];
    }).overrideAttrs
      (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          theme_dir=Catppuccin-${upperFlavor}-${upperAccent}
          cp ${nixosLogoPath} $out/share/plasma/look-and-feel/$theme_dir/contents/splash/images/Logo.png
        '';
      });
})
