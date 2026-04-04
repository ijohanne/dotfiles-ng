{
  homeManager = import ./home-manager-modules.nix;
  lib = import ./lib;
  nixos = import ./nixos-modules.nix;
  darwin = import ./darwin-modules.nix;
  packages = import ./packages;
  patches = import ./patches;
}
