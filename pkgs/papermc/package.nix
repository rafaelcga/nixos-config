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
  version = "1.21.11-104";
  hash = "sha256-ApaR1DFP7+Vo1s9Zai3G/tyISgR8cutacf7oPDYxUiY=";

  src = fetchurl {
    url = "https://fill-data.papermc.io/v1/objects/029691d4314fefe568d6cf596a2dc6fedc884a047c72eb5a71fee83c36315226/paper-1.21.11-104.jar";
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
