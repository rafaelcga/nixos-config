{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "datahugger";
  version = "0.13";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-exXaUmzldVa3cm9QJNOqqpYvVfPYEz1vgoAQpXEjaY4=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    jsonpath-ng
    requests
    requests-cache
    scitree
    tqdm
  ];

  optional-dependencies = with python3.pkgs; {
    all = [
      datasets
    ];
    benchmark = [
      pandas
      tabulate
    ];
    docs = [
      mkdocs-material
    ];
    lint = [
      ruff
    ];
    test = [
      pytest
      pytest-xdist
      tomli
    ];
  };

  pythonImportsCheck = [
    "datahugger"
  ];

  meta = {
    description = "One downloader for many scientific data and code repositories";
    homepage = "https://pypi.org/project/datahugger";
    license = lib.licenses.mit;
    mainProgram = "datahugger";
  };
})
