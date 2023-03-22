{ stdenv
, lib
, makeWrapper
, writeScriptBin
, fetchgit
, fetchFromGitHub
, fetchzip
, fetchurl
, runCommand
, cmake
, git
, glew
, SDL2
, zlib
, minizip
, libjpeg
, curl
, lua5_4
, libogg
, libtheora
, freetype
, libpng
, sqlite
, openal
, unzip
, cjson
}:

let
  version = "2.81.1";
  pkgname = "etlegacy";
  lua = lua5_4;
  mirror = "https://mirror.etlegacy.com";
  fetchAsset = {asset, sha256}: fetchurl
    { url = mirror + "/etmain/" + asset;
    inherit sha256;
    };
  pak0 = fetchAsset
    { asset = "pak0.pk3";
    sha256 = "712966b20e06523fe81419516500e499c86b2b4fec823856ddbd333fcb3d26e5";
    };
  pak1 = fetchAsset
    { asset = "pak1.pk3";
    sha256 = "5610fd749024405b4425a7ce6397e58187b941d22092ef11d4844b427df53e5d";
    };
  pak2 = fetchAsset
    { asset = "pak2.pk3";
    sha256 = "a48ab749a1a12ab4d9137286b1f23d642c29da59845b2bafc8f64e052cf06f3e";
    };
  fakeGit = writeScriptBin "git" ''
    #! ${stdenv.shell} -e
    if [ "$1" = "describe" ]; then
      if [ -r VERSION.txt ]; then
        . <(sed 's/^\(VERSION_[A-Z]\+\) \(.*\)/\1=\2/' VERSION.txt)
        VERSION="$VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH"
      fi
      if [ "$VERSION" != "" ]; then
        echo $VERSION
      else
        echo "Unable to determine version"
        exit 1
      fi
    fi
  '';
  gamedir = stdenv.mkDerivation rec {
    pname = pkgname;
    inherit version;

    src = fetchgit {
      url = "https://github.com/etlegacy/etlegacy.git";
      rev = "refs/tags/v" + version;
      sha256 = "sha256-CGXtc51vaId/SHbD34ZeT0gPsrl7p2DEw/Kp+GBZIaA=";  # 2.81.1
      fetchSubmodules= false;
    };

    nativeBuildInputs = [ cmake fakeGit git makeWrapper unzip cjson ];
    buildInputs = [
      glew SDL2 zlib minizip libjpeg curl lua libogg libtheora freetype libpng sqlite openal
    ];

    preBuild = ''
      export SOURCE_DATE_EPOCH=$(date +%s)
      export CI="true"
    '';

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCROSS_COMPILE32=0"
      "-DBUILD_SERVER=0"
      "-DBUILD_CLIENT=1"
      "-DBUNDLED_JPEG=0"
      "-DBUNDLED_LIBS=0"
      "-DINSTALL_EXTRA=0"
      "-DINSTALL_OMNIBOT=0"
      "-DINSTALL_GEOIP=0"
      "-DINSTALL_WOLFADMIN=0"
      "-DFEATURE_AUTOUPDATE=0"
      "-DINSTALL_DEFAULT_BASEDIR=."
      "-DINSTALL_DEFAULT_BINDIR=."
      "-DINSTALL_DEFAULT_MODDIR=."
    ];

    postInstall = ''
      ETMAIN=$out/etmain
      mkdir -p $ETMAIN
      ln -s ${pak0} $ETMAIN/pak0.pk3
      ln -s ${pak1} $ETMAIN/pak1.pk3
      ln -s ${pak2} $ETMAIN/pak2.pk3
    '';

    meta = with lib; {
      description = "ET: Legacy is an open source project based on the code of Wolfenstein: Enemy Territory which was released in 2010 under the terms of the GPLv3 license";
      homepage = "https://etlegacy.com";
      platforms = [ "i686-linux" "x86_64-linux" ];
      license = licenses.gpl3;
      maintainers = with maintainers; [ ashleyghooper ];
    };
  };
in runCommand pkgname { buildInputs = [ makeWrapper ]; } ''
  BIN=$out/bin
  mkdir -p $BIN
  # Create wrapper to change directory to the gamedir and launch
  EXE=${if stdenv.hostPlatform.system == "i686-linux" then "etl.i386" else "etl.x86_64"}
  makeWrapper ${gamedir}/$EXE $BIN/$EXE --chdir ${gamedir}
  # Propagate .desktop files
  cp -r ${gamedir}/share $out/share
''
