{
  lib,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "jkbx";
  version = "0.1.0";
  cargoLock.lockFile = ./Cargo.lock;
  src = lib.cleanSource ./.;

  meta = with lib; {
    description = "Music host for frippy";
    mainProgram = "jkbx";
  };
}
