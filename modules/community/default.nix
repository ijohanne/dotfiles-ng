{
  homeManager = import ./home-manager-modules.nix;
  lib = import ./lib;
  shared = {
    nixCaches = ./shared/nix-caches.nix;
  };
  nixos = import ./nixos-modules.nix;
  darwin = import ./darwin-modules.nix;
  packages = import ./packages;
  patches = import ./patches;
}
