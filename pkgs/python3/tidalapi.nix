{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "tidalapi";
  version = "0.8.11";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-yN6ow4K+N74SQTZlyLgaUW7NbpfAmXpWXyrhshou0WU=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies = with python3.pkgs; [
    isodate
    mpegdash
    pyaes
    python-dateutil
    ratelimit
    requests
    typing-extensions
  ];

  pythonImportsCheck = [
    "tidalapi"
  ];

  meta = {
    description = "Unofficial API for TIDAL music streaming service";
    homepage = "https://pypi.org/project/tidalapi/";
    license = lib.licenses.lgpl3Only;
    mainProgram = "tidalapi";
  };
}
