final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      pyqtdarktheme-fork = pyfinal.toPythonModule (final.callPackage ./pyqtdarktheme-fork.nix { });
      rich = pyfinal.toPythonModule (final.callPackage ./rich.nix { });
      typer = pyfinal.toPythonModule (final.callPackage ./typer.nix { });
    };
  };
}
