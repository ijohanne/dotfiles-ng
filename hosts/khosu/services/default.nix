{ config, ... }:

{
  imports = [
    ./postfix.nix
    ./wireguard.nix
  ];

  sops.secrets.wireguard_private_key = { };
}
