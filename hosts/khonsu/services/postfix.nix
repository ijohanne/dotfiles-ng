{ config, pkgs, lib, ... }:

let
  relayDomains = [
    "shouldidrink.today"
    "unixpimps.net"
    "nordic-t.me"
  ];

  transportMap = lib.concatStringsSep "\n" (
    map (d: "${d} smtp:[pakhet.est.unixpimps.net]:2525") relayDomains
  );
in
{
  # ACME cert for STARTTLS (HTTP-01 via standalone)
  security.acme = {
    acceptTerms = true;
    defaults.email = "ij@unixpimps.net";
    certs."khonsu.unixpimps.net" = {
      listenHTTP = ":80";
      group = "postfix";
    };
  };

  # Generate sasldb2 from sops secret
  systemd.services.postfix-sasldb = {
    description = "Generate Cyrus SASL database for Postfix";
    wantedBy = [ "multi-user.target" ];
    before = [ "postfix.service" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.cyrus_sasl ];
    script = ''
      mkdir -p /etc/sasl2
      PASSWORD=$(cat ${config.sops.secrets.relay_sasl_password.path})
      echo "$PASSWORD" | saslpasswd2 -c -p -f /etc/sasl2/sasldb2 -u khonsu.unixpimps.net relay
      chown postfix:postfix /etc/sasl2/sasldb2
      chmod 0600 /etc/sasl2/sasldb2

      cat > /etc/sasl2/smtpd.conf << EOF
      pwcheck_method: auxprop
      auxprop_plugin: sasldb
      mech_list: PLAIN LOGIN CRAM-MD5
      sasldb_path: /etc/sasl2/sasldb2
      EOF
    '';
  };

  services.postfix = {
    enable = true;

    mapFiles."transport" = pkgs.writeText "transport" transportMap;

    settings.main = {
      smtpd_tls_chain_files = [
        "/var/lib/acme/khonsu.unixpimps.net/key.pem"
        "/var/lib/acme/khonsu.unixpimps.net/fullchain.pem"
      ];
      myhostname = "khonsu.unixpimps.net";
      mydomain = "unixpimps.net";
      myorigin = "khonsu.unixpimps.net";
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
      smtpd_recipient_restrictions = "permit_sasl_authenticated, reject_unauth_destination";
      smtpd_helo_restrictions = "permit_mynetworks, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname";

      # SASL (configured per-service in masterConfig)
      smtpd_sasl_type = "cyrus";
      smtpd_sasl_path = "smtpd";
    };

    settings.master = {
      # Port 2525: authenticated relay submission from pakhet
      "2525" = {
        type = "inet";
        private = false;
        command = "smtpd";
        args = [
          "-o" "smtpd_sasl_auth_enable=yes"
          "-o" "smtpd_sasl_security_options=noanonymous"
          "-o" "smtpd_recipient_restrictions=permit_sasl_authenticated,reject"
          "-o" "smtpd_tls_security_level=may"
        ];
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 25 80 2525 ];
}
