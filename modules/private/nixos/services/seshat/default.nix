{ modules, ... }:

{
  imports = [
    ./backup.nix
    ./postgresql.nix
    ./screeny.nix
    ./wireguard.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg0"; })
  ];
}
