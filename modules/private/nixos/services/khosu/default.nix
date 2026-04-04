{ network, config, modules, ... }:

{
  imports = [
    ./postfix.nix
    ./wireguard.nix
    ./node-exporter.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg0"; })
  ];

  sops.secrets.wireguard_private_key = { };
}
