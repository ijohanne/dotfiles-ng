{
  home = {
    users = {
      ij = ./home/users/ij.nix;
      mj = ./home/users/mj.nix;
    };
  };

  nixos = {
    aspects = {
      managedRemoteHost = ./nixos/aspects/managed-remote-host.nix;
      workstationSecrets = ./nixos/aspects/workstation-secrets.nix;
    };
  };

  darwin = {
    aspects = {
      workstationSecrets = ./darwin/aspects/workstation-secrets.nix;
    };
  };
}
