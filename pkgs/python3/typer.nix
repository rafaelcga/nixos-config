{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "typer";
  version = "0.20.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-aFhesbASA2icQZm8RA1r5hbwhR6fDrQeSneIRcWg/Vs=";
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
