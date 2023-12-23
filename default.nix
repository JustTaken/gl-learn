{
  stdenv,
}:

stdenv.mkDerivation {
  pname = "zigTest";
  version = "v0.1";
  src = ./.;
  buildPhase = ''
    mkdir -p $out/bin
    zig build --cache-dir $out/
  '';

  installPhase = ''
    ls -la
    exit 1
    # cp zig-out/bin/gl_learn $out/bin/zigTest
  '';
}


