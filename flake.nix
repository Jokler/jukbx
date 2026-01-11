{
  description = "Music host for frippy";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs supportedSystems;
    overlayList = [self.overlays.default];
    pkgsBySystem = forEachSystem (system:
      import nixpkgs {
        inherit system;
        overlays = overlayList;
      });
  in {
    overlays.default = final: prev: {jkbx = final.callPackage ./package.nix {};};

    packages = forEachSystem (system: {
      jkbx = pkgsBySystem.${system}.jkbx;
      default = pkgsBySystem.${system}.jkbx;
    });
    devShells = forEachSystem (system: {
      default = pkgsBySystem.${system}.callPackage ./shell.nix {};
    });

    nixosModules = import ./nixos-modules {overlays = overlayList;};
  };
}
