{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "synergy-dataset";
  version = "1.2";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-6rTLwYpBWkoj7EIJy3ZZt3SY5tWEmNejIepSn8fqRP4=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    pyalex
    requests
    tabulate
    tqdm
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
    "synergy_dataset"
  ];

  meta = {
    description = "Python package for the SYNERGY dataset";
    homepage = "https://pypi.org/project/synergy-dataset";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "synergy-dataset";
  };
})
