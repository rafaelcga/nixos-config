{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "tidalapi";
  version = "0.8.10";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-9bfWqxnP1AkHlBIAqR1JHxbRtosDI6+bBmC7c54Kq4A=";
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
