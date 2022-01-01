{ version, source, cargoSha256 }:
{ makeRustPlatform
, fenix
, fetchFromGitHub
, lib
, system
, pkgs
, ...
}:

let
  rustToolchain = fenix.stable;
  rustPlatform = makeRustPlatform {
    inherit (rustToolchain) cargo rustc;
  };
in
rustPlatform.buildRustPackage rec {
  inherit version;

  pname = "prisma-engines";
  src = source;

  OPENSSL_NO_VENDOR = 1;

  inherit cargoSha256;

  nativeBuildInputs = [ pkgs.pkg-config ];

  buildInputs = [
    pkgs.openssl
    pkgs.protobuf
  ];

  preBuild = ''
    export OPENSSL_DIR=${lib.getDev pkgs.openssl}
    export OPENSSL_LIB_DIR=${pkgs.openssl.out}/lib

    export PROTOC=${pkgs.protobuf}/bin/protoc
    export PROTOC_INCLUDE="${pkgs.protobuf}/include"

    export SQLITE_MAX_VARIABLE_NUMBER=250000
    export SQLITE_MAX_EXPR_DEPTH=10000
  '';

  cargoBuildFlags = "-p query-engine -p query-engine-node-api -p migration-engine-cli -p introspection-core -p prisma-fmt";

  postInstall = ''
    mv $out/lib/libquery_engine.so $out/lib/libquery_engine.node
  '';

  doCheck = false;

  meta = with lib; {
    description = "A collection of engines that power the core stack for prisma";
    homepage = "https://www.prisma.io/";
    license = licenses.asl20;
    platforms = platforms.unix;
  };
}
