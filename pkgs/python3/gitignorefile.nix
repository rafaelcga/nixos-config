{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "gitignorefile";
  version = "1.1.2";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-zh9sl9RtdoTT3Tz3aBhaOyUqcV4Ca2/JAQO2TYJuRlY=";
  };

  build-system = [
    python3.pkgs.setuptools
  ];

  pythonImportsCheck = [
    "gitignorefile"
  ];

  meta = {
    description = "A spec-compliant `.gitignore` parser for Python";
    homepage = "https://pypi.org/project/gitignorefile";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "gitignorefile";
  };
})
