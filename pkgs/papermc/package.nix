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
  version = "1.21.11-96";
  hash = "sha256-B9rvkwGGolik524o/gV7Ep+nVJEhMOo1XIAzileS5gA=";

  src = fetchurl {
    url = "https://fill-data.papermc.io/v1/objects/07daef930186a258a4e76e28fe057b129fa754912130ea355c80338a5792e600/paper-1.21.11-96.jar";
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
