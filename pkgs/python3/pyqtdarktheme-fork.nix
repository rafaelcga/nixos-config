{
  lib,
  python3,
  fetchPypi,
  fetchFromGitHub,
}:

let
  darkdetect-pinned = python3.pkgs.darkdetect.overrideAttrs (oldAttrs: rec {
    version = "0.7.1";
    src = fetchFromGitHub {
      owner = "albertosottile";
      repo = "darkdetect";
      rev = "v${version}";
      hash = "sha256-W8rphkH+Gd40BYVk5n4mOlU7hMFuPei8VnyuDngSHkQ=";
    };
  });
in

python3.pkgs.buildPythonApplication rec {
  pname = "pyqtdarktheme-fork";
  version = "2.3.4";
  pyproject = true;

  src = fetchPypi {
    pname = "pyqtdarktheme_fork";
    inherit version;
    hash = "sha256-Kl+rnSEi5S93KnCI6Hvh/Ar3ZzRuX6CxMz5oE+uyEWw=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies = [
    darkdetect-pinned
  ];

  pythonImportsCheck = [
    "qdarktheme"
  ];

  meta = {
    description = "Flat dark theme for PySide and PyQt";
    homepage = "https://pypi.org/project/PyQtDarkTheme-fork/";
    license = lib.licenses.mit;
    mainProgram = "pyqtdarktheme-fork";
  };
}
