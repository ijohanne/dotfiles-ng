{ interfaces, network, ... }:

{
  imports = [
    (import ./dns.nix { inherit network; })
    (import ./firewall.nix { inherit interfaces network; })
    ./avahi.nix
    (import ./igmpproxy.nix { inherit interfaces; })
    ./bird.nix
    (import ./kea.nix { inherit network; })
    ./wireguard.nix
    ./multicast-relay.nix
    (import ./monitoring { inherit network; })
    (import ./prometheus.nix { inherit network; })
    ./cloudflare.nix
  ];

  services.vnstat.enable = true;

  sops.secrets.cloudflare_api_token = {};
  sops.secrets.grafana_admin_password = {};
  sops.secrets.unpoller_password = {};
  sops.secrets.fireboard_token = {};
  sops.secrets.hue_api_key = {};
  sops.secrets.tplink_username = {};
  sops.secrets.tplink_password = {};
  sops.secrets.smtp_pass_brother = {};
}
