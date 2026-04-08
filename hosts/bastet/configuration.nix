{ config, lib, pkgs, ... }:

{
  imports = [
    ../rpi4-image/base.nix
  ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=ES
    options brcmfmac roamoff=1 feature_disable=0x82000
  '';

  networking = {
    hostName = lib.mkForce "bastet";
    useDHCP = lib.mkForce false;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      ensureProfiles = {
        environmentFiles = [ "/etc/NetworkManager/system-connections.env" ];
        profiles."UNIXPIMPSNET" = {
          connection = {
            id = "UNIXPIMPSNET";
            type = "wifi";
            autoconnect = "true";
            permissions = "";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "UNIXPIMPSNET";
          };
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$WIFI_PSK";
          };
          ipv4.method = "auto";
          ipv6.method = "ignore";
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
    };
  };

  systemd.services.rfkill-unblock-wifi = {
    description = "Unblock WiFi";
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock wifi";
      RemainAfterExit = true;
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
