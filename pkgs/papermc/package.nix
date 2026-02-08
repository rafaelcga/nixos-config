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
  version = "1.21.11-111";
  hash = "sha256-gqSHq4wtD28HK4267ckhjIWuOn0WeAgSRGKySJVb7sM=";

  src = fetchurl {
    url = "https://fill-data.papermc.io/v1/objects/82a487ab8c2d0f6f072b8dbaedc9218c85ae3a7d167808124462b248955beec3/paper-1.21.11-111.jar";
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
