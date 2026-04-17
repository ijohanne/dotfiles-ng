{ config, lib, pkgs, modules, ... }:

let
  kmsOverlay = ''
    [pi4]
    dtoverlay=vc4-kms-v3d
  '';
in

{
  imports = [
    ../rpi4-image/base.nix
    modules.public.nixos.services.nodeExporterBase
  ];

  sdImage.populateFirmwareCommands = lib.mkAfter ''
    cat >> firmware/config.txt <<'EOF'

    ${kmsOverlay}
    EOF
  '';

  networking = {
    hostName = lib.mkForce "bastet";
    firewall.allowedTCPPorts = [
      22
      9100
      9199
    ];
  };

  services.openssh.hostKeys = lib.mkForce [
    {
      path = "/var/lib/bootstrap/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/bootstrap 0700 root root -"
  ];

  system.activationScripts.bastetRpiGlDriver.text = ''
    config=/boot/firmware/config.txt

    if [ ! -e "$config" ]; then
      exit 0
    fi

    tmp="$(${pkgs.coreutils}/bin/mktemp)"

    ${pkgs.gawk}/bin/awk '
      /^\[pi4\]$/ {
        pending_pi4 = 1
        next
      }

      /^dtoverlay=vc4-(f)?kms-v3d$/ {
        if (pending_pi4) {
          pending_pi4 = 0
        }
        next
      }

      {
        if (pending_pi4) {
          print "[pi4]"
          pending_pi4 = 0
        }
        print
      }

      END {
        if (pending_pi4) {
          print "[pi4]"
        }
      }
    ' "$config" > "$tmp"

    cat >> "$tmp" <<'EOF'

    ${kmsOverlay}
    EOF

    if ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$config"; then
      ${pkgs.coreutils}/bin/install -m 0644 "$tmp" "$config"
    fi

    rm -f "$tmp"
  '';

  sops = {
    defaultSopsFile = ../../secrets/bastet.yaml;
    age = {
      keyFile = lib.mkForce null;
      generateKey = lib.mkForce false;
      # bastet's Wi-Fi secrets are encrypted to its precomputed SSH host key.
      sshKeyPaths = [ "/var/lib/bootstrap/ssh_host_ed25519_key" ];
    };

    secrets = {
      ssh_host_ed25519_key = {
        path = "/var/lib/bootstrap/ssh_host_ed25519_key";
        mode = "0600";
        restartUnits = [ "sshd.service" ];
      };
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
    nutVariables = [
      "battery.charge"
      "battery.runtime"
      "input.voltage"
      "output.voltage"
      "ups.beeper.status"
      "ups.load"
      "ups.power.nominal"
      "ups.realpower"
      "ups.status"
    ];
  };

  system.stateVersion = "25.05";
}
