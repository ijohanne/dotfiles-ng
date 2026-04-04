{ host, sopsFile, installDeployScript ? true }:
{ config, pkgs, lib, modules, ... }:

let
  deploy = modules.public.lib.deploy { inherit pkgs; };
in
{
  environment.systemPackages = lib.optionals installDeployScript [
    (deploy.mkDeployScript {
      name = "deploy-${host}";
      inherit host;
    })
  ];

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_builder_access_tokens.path}
  '';

  sops = {
    defaultSopsFile = sopsFile;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
    secrets.nix_builder_access_tokens = lib.mkDefault { };
  };
}
