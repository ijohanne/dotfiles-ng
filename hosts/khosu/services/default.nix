{ network, config, ... }:

{
  imports = [
    ./postfix.nix
    ./wireguard.nix
    ./node-exporter.nix
  ];

  sops.secrets.wireguard_private_key = { };
}
