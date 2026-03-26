{ network, config, ... }:

{
  imports = [
    ./postfix.nix
    ./wireguard.nix
    ./node-exporter.nix
    (import ../../../configs/wireguard-watchdog.nix { interface = "wg0"; })
  ];

  sops.secrets.wireguard_private_key = { };
}
