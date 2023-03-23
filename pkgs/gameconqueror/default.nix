{ lib
, autoconf
, automake
, fetchFromGitHub
, glib
, gobject-introspection
, gtk3
, intltool
, libtool
, python3
, python310Packages
, readline
, stdenv
, wrapGAppsHook
, desktop-file-utils
, appstream-glib
, pango
, gdk-pixbuf
, libnotify
, libadwaita
, gsettings-desktop-schemas
, substituteAll
}:

python3.pkgs.buildPythonApplication rec {
  format = "other";
  pname = "gameconqueror";
  version = "0.17";

  src = fetchFromGitHub {
    owner  = "scanmem";
    repo   = "scanmem";
    rev    = "v${version}";
    sha256 = "17p8sh0rj8yqz36ria5bp48c8523zzw3y9g8sbm2jwq7sc27i7s9";
  };

  patches = [
    # Make PyGObject’s gi library available.
    (substituteAll {
      src = ./fix-paths.patch;
      pythonPaths = lib.concatMapStringsSep ", " (pkg: "'${pkg}/${python3.sitePackages}'") [
        python3.pkgs.pygobject3
      ];
    })
  ];

  nativeBuildInputs = [
    autoconf
    automake
    intltool
    libtool
    gobject-introspection
    wrapGAppsHook
    # desktop-file-utils
    ];

  buildInputs = [
    # wrapGAppsHook
    readline
    gtk3
    libnotify
    gsettings-desktop-schemas
    # (python3.withPackages (ps: with ps; [ pygobject3 ]))
  ];

  propagatedBuildInputs = with python3.pkgs; [
    pygobject3
    pycairo
    dbus-python
  ] ++ [
    gobject-introspection
  ]
  ;


  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';

  strictDeps = false; # broken with gobject-introspection setup hook https://github.com/NixOS/nixpkgs/issues/56943
  dontWrapGApps = true; # prevent double wrapping
  # doCheck = false;

  preConfigure = ''
    ./autogen.sh
  '';

  configureFlags = ["--enable-gui"];

  meta = with lib; {
    homepage = "https://github.com/scanmem/scanmem/tree/master/gui";
    description = "Graphical game cheating tool under Linux, a frontend for scanmem.";
    maintainers = [ ];
    platforms = platforms.linux;
    license = licenses.gpl3;
  };
}