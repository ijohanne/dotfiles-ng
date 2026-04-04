{
  inventory = import ./inventory;

  home = {
    users = {
      ij = ./home/users/ij.nix;
      mj = ./home/users/mj.nix;
    };
  };

  nixos = {
    aspects = {
      anubisServices = ./nixos/aspects/anubis-services.nix;
      gooseServices = ./nixos/aspects/goose-services.nix;
      khosuServices = ./nixos/aspects/khosu-services.nix;
      managedRemoteHost = ./nixos/aspects/managed-remote-host.nix;
      pakhetServices = ./nixos/aspects/pakhet-services.nix;
      workstationSecrets = ./nixos/aspects/workstation-secrets.nix;
    };
  };

  darwin = {
    aspects = {
      remoteBuilderClient = ./darwin/aspects/remote-builder-client.nix;
      workstationSecrets = ./darwin/aspects/workstation-secrets.nix;
    };
  };
}
