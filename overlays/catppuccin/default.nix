{ config, lib, ... }:
let
  upperFlavor = lib.local.capitalizeFirst config.catppuccin.flavor or "";
  upperAccent = lib.local.capitalizeFirst config.catppuccin.accent or "";
  nixosLogoPath = ../../resources/splash/nix-snowflake-rainbow-pastel.png;
  splashPreviewPath = ../../resources/splash/preview.png;
  blankWallpaperPath = ../../resources/wallpapers/blank_wall.png;
in
(final: prev: {
  catppuccin-kde =
    (prev.catppuccin-kde.override {
      flavour = [ config.catppuccin.flavor ];
      accents = [ config.catppuccin.accent ];
    }).overrideAttrs
      (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          theme_dir="Catppuccin-${upperFlavor}-${upperAccent}"
          contents_dir="$out/share/plasma/look-and-feel/$theme_dir/contents"
          cp ${nixosLogoPath} $contents_dir/splash/images/Logo.png
          cp ${splashPreviewPath} $contents_dir/previews/splash.png
        '';
      });

  catppuccin-papirus-folders = prev.catppuccin-papirus-folders.override {
    inherit (config.catppuccin) flavor accent;
  };

  catppuccin-sddm = prev.catppuccin-sddm.override {
    inherit (config.catppuccin) flavor accent;
    font = "JetBrainsMono Nerd Font";
    fontSize = 12;
    background = blankWallpaperPath;
    userIcon = true;
  };
})
