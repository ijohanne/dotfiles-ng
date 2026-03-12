{ inputs, config, pkgs, lib, user, ... }:

let
  network = import ../../configs/network.nix { inherit lib; };
  deploy = import ../../configs/deploy { inherit pkgs; };
in
{
  imports = [
    ../../configs/server.nix
    ./hardware-configuration.nix
    (import ./services { inherit network; })
  ];

  networking = {
    hostName = "pakhet";
    useDHCP = true;
    nameservers = [ "${network.hosts.goose.ips.wired}" ];
  };

  # kresd is pulled in by nixos-mailserver for DANE — keep it for postfix
  # but don't let it hijack resolv.conf; system DNS goes to goose
  networking.resolvconf.useLocalResolver = lib.mkForce false;

  time.timeZone = "Europe/Madrid";

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix_builder_access_tokens.path}
  '';

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ping6" ''exec ping -6 "$@"'')
    (deploy.mkDeployScript {
      name = "deploy-pakhet";
      host = "pakhet";
    })
  ];

  sops = {
    defaultSopsFile = ../../secrets/pakhet.yaml;
    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };
  };

  system.stateVersion = "22.05";
}
