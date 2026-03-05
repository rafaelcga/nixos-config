{ lib }:
final: prev: {
  python3 = prev.python3.override {
    packageOverrides =
      pyfinal: pyprev:
      lib.genAttrs [
        "asreview"
        "asreview-dory"
        "datahugger"
        "gitignorefile"
        "pyalex"
        "rispy"
        "scisort"
        "scitree"
        "synergy-dataset"
      ] (name: pyfinal.toPythonModule (final.callPackage ./${name}.nix { }));
  };
}
