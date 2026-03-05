{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "scisort";
  version = "0.5.3";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-UaWEED9F17tg0Yt8LxcFZqowjH4HyefN02fnzK/lVtY=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    natsort
  ];

  optional-dependencies = with python3.pkgs; {
    lint = [
      flake8
      flake8-import-order
    ];
    test = [
      pandas
      pytest
    ];
  };

  pythonImportsCheck = [
    "scisort"
  ];

  meta = {
    description = "Smart sorting algorithm for files and folders in research projects and repositories";
    homepage = "https://pypi.org/project/scisort";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "scisort";
  };
})
