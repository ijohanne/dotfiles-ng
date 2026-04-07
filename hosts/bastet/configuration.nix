{ config, lib, ... }:

{
  imports = [
    ../rpi4-image/base.nix
  ];

  networking = {
    hostName = lib.mkForce "bastet";
    wireless = {
      enable = lib.mkForce true;
      interfaces = [ "wlan0" ];
      secretsFile = config.sops.templates."wireless.conf".path;
      networks = {
        "UNIXPIMPSNET" = {
          pskRaw = "ext:wifi_psk";
          priority = 20;
        };
      };
    };
    firewall.allowedTCPPorts = [
      22
      9199
    ];
  };

  services.openssh.hostKeys = lib.mkForce [
    {
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  sops = {
    defaultSopsFile = ../../secrets/bastet.yaml;
    age = {
      keyFile = lib.mkForce null;
      generateKey = lib.mkForce false;
      # bastet's Wi-Fi secrets are encrypted to its precomputed SSH host key.
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      ssh_host_ed25519_key = {
        path = "/etc/ssh/ssh_host_ed25519_key";
        mode = "0600";
        restartUnits = [ "sshd.service" ];
      };
      wifi_psk = { };
    };

    templates."wireless.conf" = {
      content = ''
        wifi_psk=${config.sops.placeholder.wifi_psk}
      '';
      restartUnits = [ "wpa_supplicant-wlan0.service" ];
    };
  };

  power.ups = {
    enable = true;
    mode = "none";

    upsd = {
      enable = true;
      listen = [{
        address = "127.0.0.1";
      }];
    };

    ups.eaton5e = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Eaton 5E Gen 2";
    };
  };

  services.prometheus.exporters.nut = {
    enable = true;
    listenAddress = "0.0.0.0";
  };

  system.stateVersion = "25.05";
}
