{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "asreview";
  version = "2.2";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-9Kpxa8N1uC0kqnr6VXcVlkekAE8I4/hRs7qTgf83zas=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    datahugger
    filelock
    flask
    flask-cors
    flask-login
    flask-mail
    flask-sqlalchemy
    gevent
    jsonschema
    numpy
    openpyxl
    pandas
    requests
    rich
    rispy
    scikit-learn
    sqlalchemy-utils
    synergy-dataset
    tomli
    tqdm
    waitress
    werkzeug
  ];

  optional-dependencies = with python3.pkgs; {
    dev = [
      asreview
      setuptools
    ];
    docs = [
      ipython
      myst-parser
      nbsphinx
      pydata-sphinx-theme
      sphinx
      sphinx-design
      sphinx-reredirects
      sphinxcontrib-youtube
    ];
    lint = [
      check-manifest
      ruff
    ];
    test = [
      coverage
      pytest
      pytest-random-order
      pytest-selenium
    ];
  };

  pythonImportsCheck = [
    "asreview"
  ];

  meta = {
    description = "ASReview LAB - A tool for AI-assisted systematic reviews";
    homepage = "https://pypi.org/project/asreview";
    license = lib.licenses.asl20;
    mainProgram = "asreview";
  };
})
