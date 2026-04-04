{ config, pkgs, lib, ... }:

let
  network = import ../../../../../configs/network.nix { inherit lib; };
  relayDomains = network.mailDomains;

  # Deliver inbound mail to pakhet via WireGuard tunnel
  transportMap = lib.concatStringsSep "\n" (
    map (d: "${d} smtp:[${network.hosts.pakhet.ip}]:25") relayDomains
  );
in
{
  # ACME cert for STARTTLS (HTTP-01 via standalone)
  security.acme = {
    acceptTerms = true;
    defaults.email = "ij@unixpimps.net";
    certs."khosu.unixpimps.net" = {
      listenHTTP = ":80";
      group = "postfix";
    };
  };

  services.postfix = {
    enable = true;

    mapFiles."transport" = pkgs.writeText "transport" transportMap;

    settings.main = {
      smtpd_tls_chain_files = [
        "/var/lib/acme/khosu.unixpimps.net/key.pem"
        "/var/lib/acme/khosu.unixpimps.net/fullchain.pem"
      ];
      myhostname = "khosu.unixpimps.net";
      mydomain = "unixpimps.net";
      myorigin = "khosu.unixpimps.net";
      mydestination = "";
      mynetworks = [ "127.0.0.0/8" "[::1]/128" ];

      # Transport
      transport_maps = "hash:/var/lib/postfix/conf/transport";
      relay_domains = relayDomains;

      # TLS
      smtpd_tls_security_level = "may";
      smtp_tls_security_level = "may";

      # Queue lifetime for backup MX behavior
      maximal_queue_lifetime = "5d";
      bounce_queue_lifetime = "5d";

      # Anti-spam on port 25
      smtpd_helo_required = "yes";
      smtpd_recipient_restrictions = "permit_mynetworks, reject_unauth_destination";
      smtpd_helo_restrictions = "permit_mynetworks, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname";
    };

    settings.master = {
      # Port 2525: relay submission from pakhet (restricted to internal networks via WireGuard)
      "2525" = {
        type = "inet";
        private = false;
        command = "smtpd";
        args = [
          "-o"
          "mynetworks=${network.hosts.pakhet.ip}/32"
          "-o"
          "smtpd_recipient_restrictions=permit_mynetworks,reject"
          "-o"
          "smtpd_tls_security_level=may"
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 25 80 ];
    trustedInterfaces = [ "wg0" ];
  };
}
