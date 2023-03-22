{ lib
, stdenv
, autoconf
, automake
, makeWrapper
, intltool
, libtool
, python3
, fetchFromGitHub
, readline
, python310Packages
, gtk3
, cairo
, gnome
, gdk-pixbuf
, glibc
, dbus
, libnotify
, wrapGAppsHook
, gobject-introspection
, polkit
, writeText
}:

let 
  version = "0.17";
  pname = "gameconqueror";

  src = fetchFromGitHub {
    owner  = "scanmem";
    repo   = "scanmem";
    rev    = "v${version}";
    sha256 = "17p8sh0rj8yqz36ria5bp48c8523zzw3y9g8sbm2jwq7sc27i7s9";
  };
  
  gameconquerorPython = python3.pkgs.buildPythonPackage rec {
    inherit pname version src;
    nativeBuildInputs = [ 
      wrapGAppsHook
      gobject-introspection
    ];
    # propagatedBuildInputs = [
    #   gtk3
    #   python3.pkgs.pygobject3
    # ];
    configurePhase = 
      let
        setupPy = writeText "setup.py" ''
          from setuptools import setup
          setup(
            name='${pname}',
            version='${version}-test',
            packages=['gameconqueror'],
          )
        '';
        initPy = writeText "__init__.py" ''
            PROGRAM_NAME = 'GameConqueror'
            PACKAGE_NAME = '${pname}'
            PACKAGE_VERSION = '${version}'
        '';
      in
      ''
        ln -s ${setupPy} setup.py
        mv -v gui gameconqueror
        ln -s ${initPy} gameconqueror/__init__.py
      '';
    doCheck = false;
  };

  pythonPreBuilt = python3.withPackages ( ps: with ps; [
    # dbus-python
    gtk3
    pygobject3
    gameconquerorPython
    
  ]);
in

stdenv.mkDerivation rec {
  inherit pname version src;
  nativeBuildInputs = [ 
    autoconf
    automake 
    intltool 
    libtool
    # pkgconfig
    # wrapGAppsHook
    # gobject-introspection
  ];

  buildInputs = [ 
    gtk3
    readline
    polkit
    libnotify
    pythonPreBuilt
    gobject-introspection
  ];

  # passthru = { pythonModule = python3; };
  # strictDeps = false;
  doCheck = false;
  # dontWrapGApps = true;

  preConfigure = ''
    ./autogen.sh
  '';

  configureFlags = ["--enable-gui"];

  # postInstall = ''
  #   install -D -m0644 org.freedesktop.gameconqueror.policy \
  #     $out/share/polkit-1/actions/org.freedesktop.gameconqueror.policy
  #   '';

  meta = with lib; {
    homepage = "https://github.com/scanmem/scanmem";
    description = "official GUI for scanmem, a Memory scanner for finding and poking addresses in executing processes";
    maintainers = [ maintainers.frnkpsycho ];
    platforms = platforms.linux;
    license = licenses.gpl3;
  };
}