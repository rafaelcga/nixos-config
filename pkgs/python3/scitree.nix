{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "scitree";
  version = "0.5.3";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-2IcMpFPx6soqfxV9NRpUQScxj5CEfcKfoQ1NGf1TQVA=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    gitignorefile
    natsort
    scisort
    seedir
  ];

  optional-dependencies = with python3.pkgs; {
    lint = [
      flake8
      flake8-import-order
    ];
    test = [
      pytest
    ];
  };

  pythonImportsCheck = [
    "scitree"
  ];

  meta = {
    description = "One downloader for many scientific data and code repositories";
    homepage = "https://pypi.org/project/scitree";
    license = lib.licenses.mit;
    mainProgram = "scitree";
  };
})
