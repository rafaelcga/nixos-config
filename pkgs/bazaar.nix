{
  lib,
  stdenv,
  fetchFromGitHub,
  blueprint-compiler,
  desktop-file-utils,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook4,
  appstream,
  flatpak,
  glib-networking,
  glycin-loaders,
  gtk4,
  json-glib,
  libadwaita,
  libdex,
  libglycin,
  libglycin-gtk4,
  libsoup_3,
  libxmlb,
  libyaml,
  md4c,
  webkitgtk_6_0,
  libsecret,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bazaar";
  version = "0.7.14";

  src = fetchFromGitHub {
    owner = "kolunmi";
    repo = "bazaar";
    tag = "v${finalAttrs.version}";
    hash = "sha256-u2fb2OtX274DT7EdC0roQyN0og2sxEcvhpDp+67VFHw=";
  };

  nativeBuildInputs = [
    blueprint-compiler
    desktop-file-utils
    meson
    ninja
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    appstream
    flatpak
    glib-networking
    gtk4
    json-glib
    libadwaita
    libdex
    libglycin
    libglycin-gtk4
    glycin-loaders
    libsoup_3
    libxmlb
    libyaml
    md4c
    webkitgtk_6_0
    libsecret
  ];

  # bazaar needs bazaar-dl-worker in path
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : $out/bin
    )
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "FlatHub-first app store for GNOME";
    homepage = "https://github.com/kolunmi/bazaar";
    license = lib.licenses.gpl3Plus;
    mainProgram = "bazaar";
    platforms = lib.platforms.linux;
  };
})
