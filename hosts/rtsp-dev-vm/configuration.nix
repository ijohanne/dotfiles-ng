{ lib, config, pkgs, user, modulesPath, modules, ... }:

let
  rtsp-linux = pkgs.callPackage modules.public.packages.rtspLinux {
    kernel = config.boot.kernelPackages.kernel;
  };
in

{
  imports = [
    modules.public.nixos.profiles.system.base
    modules.public.nixos.profiles.system.qemuGuest
  ];

  networking = {
    hostName = "rtsp-dev";
    useDHCP = true;
    firewall.enable = false;
    nftables = {
      enable = true;
      checkRuleset = false;
      ruleset = ''
        table ip filter {
          chain input {
            type filter hook input priority filter; policy accept;
          }

          chain forward {
            type filter hook forward priority filter; policy accept;
            ct helper "rtsp" accept
          }
        }

        table ip nat {
          chain prerouting {
            type nat hook prerouting priority -100; policy accept;
          }

          chain postrouting {
            type nat hook postrouting priority filter; policy accept;
            oifname "eth0" masquerade
          }
        }

        table ip raw {
          ct helper rtsp-helper {
            type "rtsp" protocol tcp;
          }

          chain prerouting {
            type filter hook prerouting priority raw; policy accept;
            tcp dport 554 ct helper set "rtsp-helper"
          }
        }
      '';
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "nf_conntrack_rtsp" "nf_nat_rtsp" ];
  boot.extraModulePackages = [ rtsp-linux ];
  boot.kernel.sysctl = {
    "net.netfilter.nf_conntrack_helper" = 1;
    "net.ipv4.ip_forward" = 1;
  };

  fileSystems."/" = {
    device = "/dev/vda";
    fsType = "ext4";
  };

  boot.loader.grub.device = "/dev/vda";

  environment.systemPackages = with pkgs; [
    tcpreplay
    tcpdump
    conntrack-tools
    nftables
    wireshark-cli
    config.boot.kernelPackages.kernel.dev
  ];

  users.users.root = {
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeFunHfY3vS2izkp7fMHk2bXuaalNijYcctAF2NGc1T"
    ];
  };

  users.users.${user.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = user.sshKeys;
  };

  system.stateVersion = "25.11";
}
