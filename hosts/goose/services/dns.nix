{ network, ... }:

{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    enableRootTrustAnchor = true;
    settings = {
      server = {
        interface = [ "0.0.0.0" ];
        access-control = [ "10.0.0.0/8 allow" "127.0.0.0/8 allow" ];
        do-tcp = "yes";
        do-udp = "yes";
        hide-identity = "yes";
        hide-version = "yes";
        harden-glue = "yes";
        harden-dnssec-stripped = "yes";
        qname-minimisation = "yes";
        use-caps-for-id = "yes";
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
        local-zone = network.reverseZones;
        local-data = network.forwardDns ++ network.reverseDns;
      };
      remote-control = {
        control-enable = true;
        control-use-cert = "no";
      };
    };
  };
}
