{ network, ... }:

{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    enableRootTrustAnchor = true;
    settings = {
      server = {
        interface = [ "0.0.0.0" ] ++ (if network.enableIPv6ULA then [ "::0" ] else []);
        access-control = [ "10.0.0.0/8 allow" "127.0.0.0/8 allow" ] ++ (if network.enableIPv6ULA then [ "fc00::/7 allow" "::1/128 allow" ] else []);
        do-tcp = "yes";
        do-udp = "yes";
        outgoing-interface = "0.0.0.0";
        hide-identity = "yes";
        hide-version = "yes";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";
        qname-minimisation = "yes";
        use-caps-for-id = "no";
        edns-buffer-size = 1232;
        cache-min-ttl = 0;
        cache-max-ttl = 14400;
        cache-max-negative-ttl = 5;
        prefetch = "yes";
        serve-expired = "yes";
        serve-expired-ttl = "7200";
        serve-expired-client-timeout = "1800";
        log-servfail = "yes";
        num-threads = 8;
        msg-cache-slabs = 8;
        rrset-cache-slabs = 8;
        infra-cache-slabs = 8;
        key-cache-slabs = 8;
        rrset-cache-size = "256m";
        rrset-roundrobin = "yes";
        msg-cache-size = "128m";
        so-rcvbuf = "1m";
        so-reuseport = "yes";
        statistics-interval = 0;
        extended-statistics = "yes";
        statistics-cumulative = "yes";
        local-zone = network.reverseZones ++ network.reverseZones6;
        local-data = network.forwardDns ++ network.reverseDns ++ network.forwardDns6 ++ network.reverseDns6;
      };
      remote-control = {
        control-enable = true;
        control-use-cert = "no";
      };
    };
  };
}
