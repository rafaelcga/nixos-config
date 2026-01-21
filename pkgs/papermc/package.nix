{
  lib,
  fetchurl,
  stdenvNoCC,
  makeBinaryWrapper,
  jre,
  udev,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "papermc";
  version = "1.21.11-99";
  hash = "sha256-hPQoMlOuflCiWybvOwPVeBgUVTT7DIonklt7rlkiK6Y=";

  src = fetchurl {
    url = "https://fill-data.papermc.io/v1/objects/84f4283253ae7e50a25b26ef3b03d57818145534fb0c8a27925b7bae59222ba6/paper-1.21.11-99.jar";
    inherit (finalAttrs) hash;
  };

  installPhase = ''
    runHook preInstall

    install -D $src $out/share/papermc/papermc.jar

    makeWrapper ${lib.getExe jre} "$out/bin/minecraft-server" \
      --append-flags "-jar $out/share/papermc/papermc.jar nogui" \
      ${lib.optionalString stdenvNoCC.hostPlatform.isLinux "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ udev ]}"}

    runHook postInstall
  '';

  nativeBuildInputs = [
    makeBinaryWrapper
  ];

  dontUnpack = true;
  preferLocalBuild = true;
  allowSubstitutes = false;

  passthru = {
    updateScript = ./update.py;
  };

  meta = {
    description = "High-performance Minecraft Server";
    homepage = "https://papermc.io/";
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "minecraft-server";
  };
})
