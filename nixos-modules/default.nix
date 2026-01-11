{overlays}: {
  jkbx = import ./jkbx-service.nix;

  overlayNixpkgsForThisInstance = {pkgs, ...}: {
    nixpkgs = {
      inherit overlays;
    };
  };
}
