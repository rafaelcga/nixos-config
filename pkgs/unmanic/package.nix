{
  lib,
  pkgs,
  stdenv,
  python3,

  fetchPypi,
  buildNpmPackage,
  fetchFromGitHub,
  autoPatchelfHook,
}:
let
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "Unmanic";
    repo = "unmanic";
    tag = version;
    hash = "sha256-mEOO6YHlvcXfBrtidm6PC3m84O2Qn4yMj8aGiZBAXqY=";
    fetchSubmodules = true;
  };

  frontend = buildNpmPackage {
    pname = "unmanic-frontend";
    inherit version src;
    sourceRoot = "${src.name}/unmanic/webserver/frontend";
    npmDepsHash = "sha256-hQN6t0J9oEBJUQDB/YxUjDbeHSQCGDlZno6YCwoz/Xc=";

    nativeBuildInputs = [ autoPatchelfHook ];

    buildInputs = [ stdenv.cc.cc.lib ];

    autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

    buildPhase = ''
      autoPatchelf node_modules
      npm run build:publish
    '';

    installPhase = ''
      mkdir -p $out
      cp -r dist/spa/* $out/
    '';
  };

  json-log-formatter = python3.pkgs.buildPythonApplication (finalAttrs: {
    pname = "json-log-formatter";
    version = "0.5.2";
    pyproject = true;

    src = fetchPypi {
      pname = "JSON-log-formatter";
      inherit (finalAttrs) version;
      hash = "sha256-exka5AVkaLryt0RcXOZRvZ7mt2tBYqR5p9hdtq4Cny0=";
    };

    build-system = [
      python3.pkgs.setuptools
    ];

    pythonImportsCheck = [
      "json_log_formatter"
    ];
  });

  tornado = python3.pkgs.buildPythonApplication (finalAttrs: {
    pname = "tornado";
    version = "6.3.3";
    pyproject = true;

    src = fetchPypi {
      inherit (finalAttrs) pname version;
      hash = "sha256-59jbQcAYHIDXbJgqrMRCwHg6LFTWQA/gKJVCAaLgMv4=";
    };

    build-system = [
      python3.pkgs.setuptools
      python3.pkgs.wheel
    ];

    pythonImportsCheck = [
      "tornado"
    ];
  });

  marshmallow = python3.pkgs.buildPythonApplication (finalAttrs: {
    pname = "marshmallow";
    version = "3.22.0";
    pyproject = true;

    src = fetchPypi {
      inherit (finalAttrs) pname version;
      hash = "sha256-SXL1KRBKIgu4Y31ZWqTJdir75/enfYLcWMFhXXDFgj4=";
    };

    build-system = [
      python3.pkgs.flit-core
    ];

    dependencies = with python3.pkgs; [
      packaging
    ];

    optional-dependencies = with python3.pkgs; {
      dev = [
        marshmallow
        pre-commit
        tox
      ];
      docs = [
        alabaster
        autodocsumm
        sphinx
        sphinx-issues
        sphinx-version-warning
      ];
      tests = [
        pytest
        pytz
        simplejson
      ];
    };

    pythonImportsCheck = [
      "marshmallow"
    ];
  });

  peewee-migrate = python3.pkgs.buildPythonApplication (finalAttrs: {
    pname = "peewee-migrate";
    version = "1.13.0";
    pyproject = true;

    src = fetchPypi {
      pname = "peewee_migrate";
      inherit (finalAttrs) version;
      hash = "sha256-GrZ/cqCTYAYVXhsxDBijL3nk3/ORfP6xARLKklGHIeU=";
    };

    build-system = [
      python3.pkgs.poetry-core
    ];

    dependencies = with python3.pkgs; [
      click
      peewee
    ];

    pythonImportsCheck = [
      "peewee_migrate"
    ];
  });

  psutil = python3.pkgs.buildPythonApplication (finalAttrs: {
    pname = "psutil";
    version = "6.0.0";
    pyproject = true;

    src = fetchPypi {
      inherit (finalAttrs) pname version;
      hash = "sha256-j6rk8xC22Wn6JsoFRTOLIfc8axXbfEqNk0pUgvqoGPI=";
    };

    build-system = [
      python3.pkgs.setuptools
      python3.pkgs.wheel
    ];

    optional-dependencies = with python3.pkgs; {
      dev = [
        abi3audit
        black
        check-manifest
        colorama
        coverage
        packaging
        psleak
        pylint
        pyperf
        pypinfo
        pyreadline3
        pytest
        pytest-cov
        pytest-instafail
        pytest-xdist
        pywin32
        requests
        rstcheck
        ruff
        setuptools
        sphinx
        sphinx-rtd-theme
        toml-sort
        twine
        validate-pyproject
        virtualenv
        vulture
        wheel
        wmi
      ];
      test = [
        psleak
        pytest
        pytest-instafail
        pytest-xdist
        pywin32
        setuptools
        wheel
        wmi
      ];
    };

    pythonImportsCheck = [
      "psutil"
    ];
  });
in
python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "unmanic";
  inherit version src;
  pyproject = true;

  build-system = [
    python3.pkgs.setuptools
  ];

  nativeBuildInputs = with pkgs; [
    git
  ];

  dependencies = with python3.pkgs; [
    inquirer
    json-log-formatter
    marshmallow
    peewee
    peewee-migrate
    psutil
    py-cpuinfo
    requests
    requests-toolbelt
    schedule
    swagger-ui-py
    tornado
    watchdog
    xxhash
  ];

  pythonImportsCheck = [
    "unmanic"
  ];

  postPatch = ''
    # Patch setup.py to skip the Node.js build step completely
    substituteInPlace setup.py \
        --replace "self.run_command('build-frontend')" ""

    # Hardcode version
    substituteInPlace setup.py \
        --replace-fail "versioninfo.version()" "'${version}'" \
        --replace-fail "versioninfo.full_version()" "'${version}'"
  '';

  postInstall =
    let
      webServerPath = "$out/lib/${python3.libPrefix}/site-packages/unmanic/webserver";
    in
    ''
      mkdir -p ${webServerPath}/public
      cp -r ${frontend}/* ${webServerPath}/public
      rm -rf ${webServerPath}/frontend
    '';

  makeWrapperArgs = [ "--prefix PATH : ${lib.makeBinPath [ pkgs.ffmpeg ]}" ];

  meta = {
    description = "Unmanic - Library Optimiser";
    homepage = "https://github.com/Unmanic/unmanic";
    license = lib.licenses.gpl3Only;
    mainProgram = "unmanic";
  };
})
