{
  shared = {
    nixCaches = ./shared/nix-caches.nix;
  };

  profiles = {
    system = {
      base = ./nixos/profiles/system/base;
      growRootSda2 = ./nixos/profiles/system/grow-root-sda2;
      qemuGuest = ./nixos/profiles/system/qemu-guest;
    };
  };

  services = {
    nodeExporterBase = ./nixos/services/node-exporter-base.nix;
    server = ./nixos/services/server.nix;
    smsGatewayClient = ./nixos/services/sms-gateway-client.nix;
    wanFailover = ./nixos/services/wan-failover.nix;
    wireguardWatchdog = ./nixos/services/wireguard-watchdog.nix;
  };

  aspects = {
    fishLoginShell = ./nixos/aspects/fish-login-shell.nix;
    gcPolicy = ./nixos/aspects/gc-policy.nix;
    localFlakeDeploy = ./nixos/aspects/local-flake-deploy.nix;
    nixCli = ./nixos/aspects/nix-cli.nix;
    serverBase = ./nixos/aspects/server-base.nix;
  };
}
