{ interfaces, network, ... }:

{ config, ... }:

{
  imports = [
    (import ./dns.nix { inherit network; })
    (import ./firewall.nix { inherit interfaces network; })
    ./avahi.nix
    (import ./igmpproxy.nix { inherit interfaces; })
    (import ./bird.nix { inherit interfaces network; })
    (import ./kea.nix { inherit network; })
    (import ./wireguard.nix { inherit network; })
    ./multicast-relay.nix
    (import ./monitoring { inherit network; })
    (import ./prometheus.nix { inherit network; })
    ./cloudflare.nix
  ];

  services.vnstat.enable = true;

  sops.secrets.cloudflare_api_token = {};
  sops.secrets.grafana_admin_password = {};
  sops.secrets.unpoller_password = { owner = "unpoller-exporter"; };
  sops.secrets.fireboard_token = {};
  sops.secrets.hue_api_key = { owner = "hue-exporter"; };
  sops.secrets.hue_api_key_secondary = { owner = "hue-exporter"; };
  sops.secrets.tplink_username = { owner = "tplink-p110-exporter"; };
  sops.secrets.tplink_password = { owner = "tplink-p110-exporter"; };
  sops.secrets.smtp_pass_brother = {};
  sops.secrets.sms_user = {};
  sops.secrets.sms_password = {};
  sops.secrets.sms_ip = {};
  sops.secrets.sms_target_number = {};
  sops.secrets.sms_modem = {};
  sops.secrets.wireguard_private_key = {};

  sops.templates."sms-env" = {
    content = ''
      SMS_USER=${config.sops.placeholder.sms_user}
      SMS_PASSWORD=${config.sops.placeholder.sms_password}
      SMS_IP=${config.sops.placeholder.sms_ip}
      SMS_TARGET_NUMBER=${config.sops.placeholder.sms_target_number}
      SMS_MODEM=${config.sops.placeholder.sms_modem}
    '';
  };
}
