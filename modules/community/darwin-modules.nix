{
  shared = {
    nixCaches = ../../configs/nix-caches.nix;
    secrets = ../../configs/secrets.nix;
  };

  aspects = {
    workstationBase = ./darwin/aspects/workstation-base.nix;
  };
}
