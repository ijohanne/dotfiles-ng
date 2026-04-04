{
  shared = {
    nixCaches = ../../configs/nix-caches.nix;
  };

  profiles = {
    system = {
      base = ../../configs/profiles/system/base;
      growRootSda2 = ../../configs/profiles/system/grow-root-sda2;
      qemuGuest = ../../configs/profiles/system/qemu-guest;
    };
  };

  services = {
    server = ../../configs/server.nix;
    wireguardWatchdog = ../../configs/wireguard-watchdog.nix;
  };

  aspects = {
    serverBase = ./nixos/aspects/server-base.nix;
  };
}
