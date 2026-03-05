{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "pyalex";
  version = "0.21";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-OfRwiFGH4OQReY00FjRTNho4NMTa5T8KGPJyR1t0l0E=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    requests
    urllib3
  ];

  optional-dependencies = with python3.pkgs; {
    lint = [
      ruff
    ];
    test = [
      dotenv
      pytest
      pytest-xdist
    ];
  };

  pythonImportsCheck = [
    "pyalex"
  ];

  meta = {
    description = "Python interface to the OpenAlex database";
    homepage = "https://pypi.org/project/pyalex";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "pyalex";
  };
})
