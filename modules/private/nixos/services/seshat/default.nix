{ modules, ... }:

{
  imports = [
    ./backup.nix
    ./node-exporter.nix
    ./postgresql.nix
    ./screeny.nix
    ./wireguard.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg0"; })
  ];
}
