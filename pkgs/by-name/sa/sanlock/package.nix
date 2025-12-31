{
  lib,
  stdenv,
  fetchFromGitHub,
  libaio,
  libuuid,
  pkg-config,
  systemd,
  util-linux,
}:
stdenv.mkDerivation rec {
  pname = "sanlock";
  version = "3.8.1";
  outputs = ["out" "dev"];

  src = fetchFromGitHub {
    repo = "sanlock";
    owner = "nirs";
    rev = "sanlock-${version}";
    sha256 = "sha256-QEkfmCYeVCa42pSZAW7sVb+65mLntV5Hx3FzclzypN0=";
  };

  postPatch = ''
    # Fix location of install and always use lib
    for f in $(find . -name Makefile -o -name 'Makefile.*'); do
        substituteInPlace "$f" \
            --replace-quiet '$(shell which install)' 'install'
        substituteInPlace "$f" \
          --replace "/usr/lib64" "/lib"
    done
  '';

  nativeBuildInputs = [pkg-config];
  buildInputs = [libaio libuuid systemd util-linux];

  buildPhase = ''
    make -C wdmd
    make -C src
    make -C reset
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    make -C src install DESTDIR=$out
    make -C wdmd install DESTDIR=$out
    make -C reset install DESTDIR=$out

    if [ -d $out/usr/include ]; then
      mkdir -p $dev/include
      mv $out/usr/include/* $dev/include/
    fi
    if [ -d $out/lib/pkgconfig ]; then
      mkdir -p $dev/lib/pkgconfig
      mv $out/lib/pkgconfig/* $dev/lib/pkgconfig/
      rmdir $out/lib/pkgconfig
    fi

    mkdir -p $out/lib/systemd/system
    install -D -m 0644 init.d/sanlock.service.native \
        $out/lib/systemd/system/sanlock.service
    install -D -m 0755 init.d/wdmd \
        $out/usr/lib/systemd/systemd-wdmd
    install -D -m 0644 init.d/wdmd.service.native \
        $out/lib/systemd/system/wdmd.service
    install -D -m 0644 init.d/sanlk-resetd.service \
        $out/lib/systemd/system/sanlk-resetd.service

    mkdir -p $out/etc/logrotate.d
    install -D -m 0644 src/logrotate.sanlock $out/etc/logrotate.d/sanlock

    mkdir -p $out/etc/sanlock
    install -D -m 0644 src/sanlock.conf $out/etc/sanlock/sanlock.conf

    mkdir -p $out/etc/sysconfig
    install -D -m 0644 init.d/wdmd.sysconfig $out/etc/sysconfig/wdmd

    mkdir -p $out/etc/wdmd.d
    install -Dd -m 0755 $out/etc/wdmd.d

    mkdir -p $out/run
    install -Dd -m 0775 $out/run/sanlock
    install -Dd -m 0775 $out/run/sanlk-resetd

    runHook postInstall
  '';

  meta = with lib; {
    description = "Shared storage lock manager for virtual machine management";
    homepage = "https://github.com/nirs/sanlock";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ashleyghooper];
  };
}
