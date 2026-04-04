{
  shared = {
    nixCaches = ../../configs/nix-caches.nix;
  };

  aspects = {
    workstationBase = ./darwin/aspects/workstation-base.nix;
  };
}
