{ lib, config, pkgs, user, users, modulesPath, modules, ... }:

let
  wifiEnvFile = "/var/lib/networkmanager/system-connections.env";
  wifiProfile = pkgs.writeText "rpi-wifi.nmconnection" ''
    [connection]
    id=$WIFI_SSID
    type=wifi
    autoconnect=true
    permissions=

    [wifi]
    mode=infrastructure
    ssid=$WIFI_SSID

    [wifi-security]
    auth-alg=open
    key-mgmt=wpa-psk
    psk=$WIFI_PSK

    [ipv4]
    method=auto

    [ipv6]
    method=ignore
  '';
in

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    modules.public.nixos.profiles.system.base
  ];

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=ES
    options brcmfmac roamoff=1 feature_disable=0x82000
  '';

  networking = {
    hostName = lib.mkDefault "rpi4";
    useDHCP = lib.mkForce false;
    networkmanager = {
      enable = true;
      wifi.powersave = false;
    };
  };

  time.timeZone = "Europe/Madrid";

  environment.shellAliases = {
    rebuild = "sudo nixos-rebuild switch --flake github:ijohanne/dotfiles-ng";
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

  systemd.services.rpi-networkmanager-ensure-wifi = {
    description = "Ensure Raspberry Pi WiFi profile";
    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    path = [
      pkgs.envsubst
      config.networking.networkmanager.package
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      profile_dir=/run/NetworkManager/system-connections
      profile="$profile_dir/wifi.nmconnection"

      if [ ! -f ${wifiEnvFile} ]; then
        rm -f "$profile"
        nmcli connection reload
        exit 0
      fi

      set -a
      . ${wifiEnvFile}
      set +a

      if [ -z "''${WIFI_SSID:-}" ] || [ -z "''${WIFI_PSK:-}" ]; then
        rm -f "$profile"
        nmcli connection reload
        exit 0
      fi

      install -d -m 700 "$profile_dir"
      envsubst -i ${wifiProfile} > "$profile"
      chmod 600 "$profile"
      nmcli connection reload
    '';
  };

  systemd.services.sshd.wantedBy = lib.mkOverride 40 [ "multi-user.target" ];

  users.users = lib.mapAttrs
    (_: u: {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = u.sshKeys;
    })
    users // {
    root = {
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = lib.concatMap (u: u.sshKeys) (lib.attrValues users);
    };
  };

  sdImage.compressImage = false;
}
