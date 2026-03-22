{ network, ... }:

{
  imports = [
    ./wireguard.nix
    ./nginx.nix
    ./qbittorrent.nix
    ./proton-port-sync.nix
  ];
}
