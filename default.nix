{
  stdenv,
}:

stdenv.mkDerivation {
  pname = "zigTest";
  version = "v0.1";
  src = ./.;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    mv zig-out/bin/zig-lang $out/bin/zigTest
  '';
}


