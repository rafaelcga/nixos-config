{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "rich";
  version = "14.3.2";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-5xLxHBpWKhGEMwb17ZmUdfCawx/7ZCgfc6sp/92os7g=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies = with python3.pkgs; [
    markdown-it-py
    pygments
  ];

  optional-dependencies = with python3.pkgs; {
    jupyter = [
      ipywidgets
    ];
  };

  pythonImportsCheck = [
    "rich"
  ];

  meta = {
    description = "Render rich text, tables, progress bars, syntax highlighting, markdown and more to the terminal";
    homepage = "https://pypi.org/project/rich/";
    license = lib.licenses.mit;
    mainProgram = "rich";
  };
}
