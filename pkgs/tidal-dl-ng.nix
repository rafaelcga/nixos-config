{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication rec {
  pname = "tidal-dl-ng";
  version = "0.31.4";
  pyproject = true;

  src = fetchPypi {
    pname = "tidal_dl_ng";
    inherit version;
    hash = "sha256-+Vkul7bYaeGNIA3DGCbhWNBFIFFvZ6f78oAXYxROHjc=";
  };

  build-system = [
    python3.pkgs.poetry-core
  ];

  dependencies =
    with python3.pkgs;
    [
      ansi2html
      coloredlogs
      dataclasses-json
      m3u8
      mutagen
      pathvalidate
      pycryptodome
      python-ffmpeg
      requests
      rich
      tidalapi
      toml
      typer
    ]
    ++ optional-dependencies.gui;

  optional-dependencies = with python3.pkgs; {
    gui = [
      pyside6
      pyqtdarktheme-fork
    ];
  };

  pythonImportsCheck = [
    "tidal_dl_ng"
  ];

  meta = {
    description = "TIDAL Medial Downloader Next Generation";
    homepage = "https://pypi.org/project/tidal-dl-ng/";
    license = lib.licenses.agpl3Only;
    mainProgram = "tidal-dl-ng";
  };
}
