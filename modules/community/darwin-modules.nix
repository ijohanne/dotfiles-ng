{
  shared = {
    nixCaches = ../../configs/nix-caches.nix;
  };

  aspects = {
    localFlakeDeploy = ./darwin/aspects/local-flake-deploy.nix;
    workstationBase = ./darwin/aspects/workstation-base.nix;
  };
}
