let
  homepageLogoPath = "/icons/nix-pastel.svg";
  nixLogoPath = ../resources/splash/nix-snowflake-rainbow-pastel.svg;
in
final: prev: {
  homepage-dashboard = prev.homepage-dashboard.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      mkdir -p $out/share/homepage/public/icons
      cp ${nixLogoPath} $out/share/homepage/public${homepageLogoPath}
    '';
  });
}
