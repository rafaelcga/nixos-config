{ inputs, config, ... }:
let
  inherit (config.modules.nixos.catppuccin) flavor accent themeName;

  nixosLogo = "${inputs.self}/resources/splash/nix-snowflake-rainbow-pastel.png";
  splashPreview = "${inputs.self}/resources/splash/preview.png";
in
final: prev: {
  catppuccin-kde =
    (prev.catppuccin-kde.override {
      flavour = [ flavor ];
      accents = [ accent ];
    }).overrideAttrs
      (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          theme_dir="${themeName}"
          contents_dir="$out/share/plasma/look-and-feel/$theme_dir/contents"
          cp ${nixosLogo} $contents_dir/splash/images/Logo.png
          cp ${splashPreview} $contents_dir/previews/splash.png
        '';
      });

  catppuccin-papirus-folders = prev.catppuccin-papirus-folders.override {
    inherit flavor accent;
  };
}
