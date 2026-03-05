{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "rispy";
  version = "0.9.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-G00aoiQ5GXltC0UCpE0y4LE2HPaKAtIxRtx5BL28kZA=";
  };

  build-system = [
    python3.pkgs.flit-core
  ];

  optional-dependencies = with python3.pkgs; {
    dev = [
      coverage
      flit
      pytest
      ruff
    ];
  };

  pythonImportsCheck = [
    "rispy"
  ];

  meta = {
    description = "A Python reader/writer of RIS reference files";
    homepage = "https://pypi.org/project/rispy";
    license = lib.licenses.mit;
    mainProgram = "rispy";
  };
})
