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
    nodeExporterBase = ./nixos/services/node-exporter-base.nix;
    server = ../../configs/server.nix;
    wanFailover = ./nixos/services/wan-failover.nix;
    wireguardWatchdog = ../../configs/wireguard-watchdog.nix;
  };

  aspects = {
    localFlakeDeploy = ./nixos/aspects/local-flake-deploy.nix;
    serverBase = ./nixos/aspects/server-base.nix;
  };
}
