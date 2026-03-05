{
  lib,
  python3,
  fetchPypi,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "asreview-dory";
  version = "1.2.2";
  pyproject = true;

  src = fetchPypi {
    pname = "asreview_dory";
    inherit (finalAttrs) version;
    hash = "sha256-iGcMyxh242EN0rk7crx0bE8eoa4FRnxYXJFhzJoCSQw=";
  };

  build-system = [
    python3.pkgs.setuptools
    python3.pkgs.setuptools-scm
  ];

  dependencies = with python3.pkgs; [
    accelerate
    asreview
    gensim
    keras
    numpy
    scikit-learn
    sentence-transformers
    torch
    xgboost
  ];

  meta = {
    description = "ASReview New Exciting Models";
    homepage = "https://pypi.org/project/asreview-dory";
    license = lib.licenses.mit;
    mainProgram = "asreview-dory";
  };
})
