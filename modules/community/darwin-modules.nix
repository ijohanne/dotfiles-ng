{
  shared = {
    nixCaches = ../../configs/nix-caches.nix;
  };

  aspects = {
    gcPolicy = ./darwin/aspects/gc-policy.nix;
    localFlakeDeploy = ./darwin/aspects/local-flake-deploy.nix;
    workstationBase = ./darwin/aspects/workstation-base.nix;
  };
}
