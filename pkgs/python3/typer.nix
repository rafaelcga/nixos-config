{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "typer";
  version = "0.21.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-6oNWB811I0O2srfOZ2iT5aAyQIImi0jyeqBYvbfSFF0=";
  };

  build-system = [
    python3.pkgs.pdm-backend
  ];

  dependencies = with python3.pkgs; [
    click
    rich
    shellingham
    typing-extensions
  ];

  pythonImportsCheck = [
    "typer"
  ];

  meta = {
    description = "Typer, build great CLIs. Easy to code. Based on Python type hints";
    homepage = "https://pypi.org/project/typer/";
    license = lib.licenses.mit;
    mainProgram = "typer";
  };
}
