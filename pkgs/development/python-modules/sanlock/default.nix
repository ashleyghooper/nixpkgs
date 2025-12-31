{
  lib,
  buildPythonPackage,
  setuptools,
  fetchFromGitHub,
  sanlockC,
}: let
  version = "3.8.1";
in
  buildPythonPackage {
    pname = "sanlock";
    version = version;

    src = fetchFromGitHub {
      repo = "sanlock";
      owner = "nirs";
      rev = "sanlock-${version}";
      sha256 = "sha256-QEkfmCYeVCa42pSZAW7sVb+65mLntV5Hx3FzclzypN0=";
    };

    sourceRoot = "source/python";

    pyproject = true;
    build-system = [setuptools];

    buildInputs = [sanlockC];

    NIX_CFLAGS_COMPILE = "-I${sanlockC.dev}/include";
    NIX_LDFLAGS = "-L${sanlockC.out}/lib";

    pythonImportsCheck = ["sanlock"];

    meta = with lib; {
      description = "Sanlock Python bindings";
      homepage = "https://github.com/nirs/sanlock";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
      maintainers = with maintainers; [ashleyghooper];
    };
  }
