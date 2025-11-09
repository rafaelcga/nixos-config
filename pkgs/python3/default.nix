final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      rich = pyfinal.toPythonModule (final.callPackage ./rich.nix { });
      typer = pyfinal.toPythonModule (final.callPackage ./typer.nix { });
    };
  };
}
