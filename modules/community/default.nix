{
  homeManager = import ./home-manager-modules.nix;
  nixos = import ./nixos-modules.nix;
  darwin = import ./darwin-modules.nix;
}
