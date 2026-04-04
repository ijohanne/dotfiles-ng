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
    smsGatewayClient = ./nixos/services/sms-gateway-client.nix;
    wanFailover = ./nixos/services/wan-failover.nix;
    wireguardWatchdog = ../../configs/wireguard-watchdog.nix;
  };

  aspects = {
    fishLoginShell = ./nixos/aspects/fish-login-shell.nix;
    gcPolicy = ./nixos/aspects/gc-policy.nix;
    localFlakeDeploy = ./nixos/aspects/local-flake-deploy.nix;
    serverBase = ./nixos/aspects/server-base.nix;
  };
}
