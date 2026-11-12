{
  lib,
  stdenv,
  python3,
  fetchPypi,
  buildNpmPackage,
  fetchFromGitHub,
  autoPatchelfHook,
  ffmpeg-full,
  git,
}:
let
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "Unmanic";
    repo = "unmanic";
    tag = version;
    hash = "sha256-1qbRs9iG1AEogaAa7QUQlLpKx0NXgqYe2VU4/J7vH5E=";
    fetchSubmodules = true;
  };

  frontend = buildNpmPackage {
    pname = "unmanic-frontend";
    inherit version src;
    sourceRoot = "${src.name}/unmanic/webserver/frontend";
    npmDepsHash = "sha256-is6vKdhsL8QJKZXF3tcj2g7RNIoGrHKgz8R2QXeOjHI=";

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [ stdenv.cc.cc.lib ];
    autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

    buildPhase = ''
      runHook preBuild
      autoPatchelf node_modules
      npm run build:publish
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/spa/* $out/
      runHook postInstall
    '';
  };

  # Unmanic pins exact versions of these (see its requirements.txt), which
  # differ from nixpkgs
  mkPythonDep =
    {
      pname,
      version,
      hash,
      pypiName ? pname,
      ...
    }@args:
    python3.pkgs.buildPythonPackage (
      removeAttrs args [
        "hash"
        "pypiName"
      ]
      // {
        pyproject = true;
        src = fetchPypi {
          pname = pypiName;
          inherit version hash;
        };
        pythonImportsCheck = [ (lib.replaceStrings [ "-" ] [ "_" ] pname) ];
      }
    );

  pythonDeps = with python3.pkgs; {
    json-log-formatter = mkPythonDep {
      pname = "json-log-formatter";
      pypiName = "JSON-log-formatter";
      version = "0.5.2";
      hash = "sha256-exka5AVkaLryt0RcXOZRvZ7mt2tBYqR5p9hdtq4Cny0=";
      build-system = [ setuptools ];
    };

    tornado = mkPythonDep {
      pname = "tornado";
      version = "6.3.3";
      hash = "sha256-59jbQcAYHIDXbJgqrMRCwHg6LFTWQA/gKJVCAaLgMv4=";
      build-system = [
        setuptools
        wheel
      ];
    };

    marshmallow = mkPythonDep {
      pname = "marshmallow";
      version = "3.22.0";
      hash = "sha256-SXL1KRBKIgu4Y31ZWqTJdir75/enfYLcWMFhXXDFgj4=";
      build-system = [ flit-core ];
      dependencies = [ packaging ];
    };

    peewee-migrate = mkPythonDep {
      pname = "peewee-migrate";
      pypiName = "peewee_migrate";
      version = "1.13.0";
      hash = "sha256-GrZ/cqCTYAYVXhsxDBijL3nk3/ORfP6xARLKklGHIeU=";
      build-system = [ poetry-core ];
      # Pins an older peewee than nixpkgs ships
      pythonRelaxDeps = [ "peewee" ];
      dependencies = [
        click
        peewee
      ];
    };

    psutil = mkPythonDep {
      pname = "psutil";
      version = "6.0.0";
      hash = "sha256-j6rk8xC22Wn6JsoFRTOLIfc8axXbfEqNk0pUgvqoGPI=";
      build-system = [
        setuptools
        wheel
      ];
    };
  };
in
python3.pkgs.buildPythonApplication {
  pname = "unmanic";
  inherit version src;
  pyproject = true;

  build-system = [ python3.pkgs.setuptools ];

  nativeBuildInputs = [ git ];

  dependencies =
    (with python3.pkgs; [
      inquirer
      peewee
      py-cpuinfo
      requests
      requests-toolbelt
      schedule
      sentry-sdk
      swagger-ui-py
      watchdog
      xxhash
    ])
    ++ lib.attrValues pythonDeps;

  pythonImportsCheck = [ "unmanic" ];

  postPatch = ''
    # Skip the Node.js build step; the frontend is built separately
    substituteInPlace setup.py \
      --replace-fail "self.run_command('build-frontend')" "" \
      --replace-fail "versioninfo.version()" "'${version}'" \
      --replace-fail "versioninfo.full_version()" "'${version}'"
  '';

  postInstall =
    let
      webServerPath = "$out/${python3.sitePackages}/unmanic/webserver";
    in
    ''
      mkdir -p ${webServerPath}/public
      cp -r ${frontend}/* ${webServerPath}/public
      rm -rf ${webServerPath}/frontend
    '';

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ ffmpeg-full ])
  ];

  # Lets nix-update refresh the frontend's npmDepsHash on version bumps
  passthru.npmDeps = frontend.npmDeps;

  meta = {
    description = "Unmanic - Library Optimiser";
    homepage = "https://github.com/Unmanic/unmanic";
    license = lib.licenses.gpl3Only;
    mainProgram = "unmanic";
  };
}
