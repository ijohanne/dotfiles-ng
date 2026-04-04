{ network, modules, ... }:

{
  imports = [
    ./wireguard.nix
    ./nginx.nix
    ./qbittorrent.nix
    ./proton-port-sync.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg1"; })
  ];
}
