{ builderHost
, builderIp
, builderSystems ? [ "x86_64-linux" "aarch64-linux" ]
, sshUser ? "root"
, sshKeyPath ? "/etc/nix/builder_ed25519"
, maxJobs ? 64
, speedFactor ? 2
, supportedFeatures ? [ "nixos-test" "benchmark" "big-parallel" "kvm" ]
, tokenSecretName ? "nix_builder_access_tokens"
, sshKeySecretPath ? "/run/secrets/nix_remote_builder_ssh_key"
}:

{ config, pkgs, user, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    builders-use-substitutes = true;
    trusted-users = [ "root" "@admin" user.username ];
  };

  nix.extraOptions = ''
    !include ${config.sops.secrets.${tokenSecretName}.path}
  '';

  nix.gc.automatic = true;

  nix.distributedBuilds = true;

  nix.buildMachines = [
    {
      hostName = builderIp;
      systems = builderSystems;
      protocol = "ssh-ng";
      inherit sshUser maxJobs speedFactor supportedFeatures;
      sshKey = sshKeyPath;
    }
  ];

  users.users.${user.username}.packages = with pkgs; [
    git
    git-lfs
    (writeShellScriptBin "setup-remote-builder" ''
      echo "Setting up SSH known host for remote builder (${builderHost})..."
      sudo ssh-keyscan -t ed25519 ${builderIp} | sudo tee -a /var/root/.ssh/known_hosts
      echo ""
      echo "Testing connection to remote builder..."
      sudo ssh -i ${sshKeyPath} ${sshUser}@${builderIp} "echo 'Connection successful!'"
      echo ""
      echo "Remote builder setup complete."
    '')
  ];

  system.activationScripts.postActivation.text = ''
    # Copy remote builder SSH key to /etc/nix for nix-daemon access
    if [ -f ${sshKeySecretPath} ]; then
      rm -f ${sshKeyPath}
      cat ${sshKeySecretPath} > ${sshKeyPath}
      chmod 600 ${sshKeyPath}
      chown root:wheel ${sshKeyPath}
    fi

    # Copy GitHub access token to user nix config for private flake inputs
    if [ -f ${config.sops.secrets.${tokenSecretName}.path} ]; then
      USER_NIX_DIR="/Users/${user.username}/.config/nix"
      mkdir -p "$USER_NIX_DIR"
      cp ${config.sops.secrets.${tokenSecretName}.path} "$USER_NIX_DIR/access-tokens.conf"
      chmod 600 "$USER_NIX_DIR/access-tokens.conf"
      chown ${user.username}:staff "$USER_NIX_DIR/access-tokens.conf"
      grep -Fxq '!include access-tokens.conf' "$USER_NIX_DIR/nix.conf" 2>/dev/null || echo '!include access-tokens.conf' >> "$USER_NIX_DIR/nix.conf"
      chown ${user.username}:staff "$USER_NIX_DIR/nix.conf"
    fi
  '';
}
