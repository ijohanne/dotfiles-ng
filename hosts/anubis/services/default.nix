{ network, ... }:

{ ... }:

{
  imports = [
    (import ./wireguard.nix { inherit network; })
    (import ./nginx.nix { inherit network; })
    ./qbittorrent.nix
    ./proton-port-sync.nix
  ];
}
