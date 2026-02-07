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
  version = "1.21.11-110";
  hash = "sha256-GHmJ+/cZBbH+rSkuX/gi+m25DQBBCS07hXOGSMrQSsU=";

  src = fetchurl {
    url = "https://fill-data.papermc.io/v1/objects/187989fbf71905b1fead292e5ff822fa6db90d0041092d3b85738648cad04ac5/paper-1.21.11-110.jar";
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
