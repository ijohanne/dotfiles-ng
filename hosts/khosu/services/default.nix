{ network, ... }:

{ config, ... }:

{
  imports = [
    ./postfix.nix
    (import ./wireguard.nix { inherit network; })
  ];

  sops.secrets.wireguard_private_key = { };
}
