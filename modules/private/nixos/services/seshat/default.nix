{ modules, ... }:

{
  imports = [
    ./wireguard.nix
    (import modules.public.nixos.services.wireguardWatchdog { interface = "wg0"; })
  ];
}
