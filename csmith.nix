{
  lib,
  stdenv,
  fetchFromGitHub,
  m4,
  makeWrapper,
  cmake,
  libbsd,
  perlPackages,
}:

stdenv.mkDerivation rec {
  pname = "csmith";
  version = "2.4.0";

  src = fetchFromGitHub {
    owner = "csmith-project";
    repo = "csmith";
    rev = "0ec6f1bad2df865beadf13c6e97ec6505887b0a5";
    sha256 = "0wfhzql9nh1pjxixq57pqz1f29jifbnb4f9mjkq6mkq28kp6yv4w";
  };

  nativeBuildInputs = [
    m4
    makeWrapper
    cmake
  ];
  buildInputs = [
    libbsd
  ]
  ++ (with perlPackages; [
    perl
    SysCPU
  ]);
  cmakeFlags = [ "-DCMAKE_POLICY_VERSION_MINIMUM=3.5" ];

  buildPhase = ''
    runHook preBuild

    cmake -DCMAKE_INSTALL_PREFIX=./tmp/ .
    make && make install

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r ./tmp/* $out

    runHook postInstall
  '';

  postInstall = ''
    substituteInPlace $out/bin/compiler_test.pl \
      --replace '$CSMITH_HOME/runtime' $out/include \
      --replace ' ''${CSMITH_HOME}/runtime' " $out/include" \
      --replace '$CSMITH_HOME/src/csmith' $out/bin/csmith

    substituteInPlace $out/bin/launchn.pl \
      --replace '../compiler_test.pl' $out/bin/compiler_test.pl \
      --replace '../$CONFIG_FILE' '$CONFIG_FILE'

    wrapProgram $out/bin/launchn.pl \
      --prefix PERL5LIB : "$PERL5LIB"

    mkdir -p $out/share/csmith
    mv $out/bin/compiler_test.in $out/share/csmith/
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Random generator of C programs";
    homepage = "https://embed.cs.utah.edu/csmith";
    # Officially, the license is this: https://github.com/csmith-project/csmith/blob/master/COPYING
    license = licenses.bsd2;
    longDescription = ''
      Csmith is a tool that can generate random C programs that statically and
      dynamically conform to the C99 standard. It is useful for stress-testing
      compilers, static analyzers, and other tools that process C code.
      Csmith has found bugs in every tool that it has tested, and has been used
      to find and report more than 400 previously unknown compiler bugs.
    '';
    maintainers = [ ];
    platforms = platforms.all;
  };
}
