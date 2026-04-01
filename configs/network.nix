{ lib }:
let
  domain = "est.unixpimps.net";

  # IPv6 ULA kill switch — set to false to disable all IPv6 ULA features
  enableIPv6ULA = true;
  ulaPrefix = "fd00:255";

  hosts = {
    # --- Gateway (goose) ---
    goose = rec {
      ips = {
        wifi   = "10.255.100.254";
        wired  = "10.255.101.254";
        guest  = "10.255.150.254";
        camera = "10.255.200.254";
        mgnt   = "10.255.254.254";
      };
      ip6s = {
        wifi   = "${ulaPrefix}:100::1";
        wired  = "${ulaPrefix}:101::1";
        mgnt   = "${ulaPrefix}:254::1";
      };
      ip = ips.mgnt;
      ip6 = "${ulaPrefix}:254::1";
      dns = [ "r0" "goose" ];
    };
    goose-ipmi = { ip = "10.255.254.210"; dns = [ "goose-ipmi-direct" "r0.ipmi" ]; };

    # --- Servers ---
    pakhet        = { ip = "10.255.101.200"; ip6 = "${ulaPrefix}:101::200"; mac = "58:9c:fc:0e:56:98"; dnat = [
      { proto = "tcp"; port = 25; }
      { proto = "tcp"; port = 80; }
      { proto = "tcp"; port = 443; }
      { proto = "tcp"; port = 465; }
      { proto = "tcp"; port = 587; }
      { proto = "tcp"; port = 993; }
      { proto = "tcp"; port = 995; }
      { proto = "tcp"; port = 2525; }
      { proto = "tcp"; port = 4190; }
    ]; };
    fatty         = { ip = "10.255.101.243"; ip6 = "${ulaPrefix}:101::243"; mac = "a8:a1:59:3e:da:ef"; };
    sobek-wired   = { ip = "10.255.101.244"; ip6 = "${ulaPrefix}:101::244"; mac = "dc:a6:32:08:7c:32"; dns = [ "sobek" ]; };
    chronos-wired = { ip = "10.255.101.202"; ip6 = "${ulaPrefix}:101::202"; mac = "dc:a6:32:34:1e:6d"; dns = [ "chronos" ]; };
    hapi          = { ip = "10.255.101.242"; ip6 = "${ulaPrefix}:101::242"; mac = "b8:27:eb:ff:f8:5f"; };
    cctax-couch   = { ip = "10.255.101.209"; ip6 = "${ulaPrefix}:101::209"; mac = "58:9c:fc:04:29:b3"; dnat = [
      { proto = "tcp"; port = 2222; toPort = 22; }
    ]; };
    cctax-node    = { ip = "10.255.101.245"; ip6 = "${ulaPrefix}:101::245"; mac = "58:9c:fc:03:64:32"; };
    obico         = { ip = "10.255.101.91"; };
    amon          = { ip = "10.255.101.241"; ip6 = "${ulaPrefix}:101::241"; mac = "dc:a6:32:60:1c:82"; };

    # --- Infrastructure ---
    cloudkey      = { ip = "10.255.254.240"; mac = "d0:21:f9:64:97:b3"; dns = [ "cloudkey-direct" ]; };
    fatty-ipmi    = { ip = "10.255.254.211"; mac = "04:42:1a:1c:6c:c1"; dns = [ "fatty-ipmi-direct" "fatty.ipmi" ]; };
    unvr          = { ip = "10.255.200.253"; mac = "e4:38:83:74:5d:a1"; };

    # --- Access Points (mgmt VLAN, static IPs set via controller) ---
    ap0           = { ip = "10.255.254.20";  mac = "d0:21:f9:8c:47:a9"; };
    ap1           = { ip = "10.255.254.19";  mac = "d0:21:f9:8c:63:b1"; };
    ap2           = { ip = "10.255.254.165"; mac = "9c:05:d6:f3:82:72"; };
    ap3           = { ip = "10.255.254.44";  mac = "e4:38:83:34:36:cc"; };

    # --- Wireless devices ---
    chronos       = { ip = "10.255.100.202"; ip6 = "${ulaPrefix}:100::202"; mac = "dc:a6:32:34:1e:6e"; dns = [ "chronos-wifi" ]; };
    sobek         = { ip = "10.255.100.203"; ip6 = "${ulaPrefix}:100::203"; mac = "dc:a6:32:08:7c:33"; dns = [ "sobek-wifi" ]; };
    canon-printserver = { ip = "10.255.100.204"; mac = "dc:a6:32:34:02:6f"; };
    dyson-office  = { ip = "10.255.100.205"; mac = "c8:ff:77:27:b3:f1"; };
    dyson-livingroom = { ip = "10.255.100.206"; mac = "c8:ff:77:67:34:b5"; };
    dyson-ian     = { ip = "10.255.100.207"; mac = "c8:ff:77:67:34:7f"; };

    # --- Printers ---
    brother-hallway = { ip = "10.255.101.230"; mac = "b4:22:00:8c:a4:a4"; dns = [ "brother-hallway" ]; };
    label-hallway   = { ip = "10.255.100.237"; mac = "ac:50:de:0a:d4:5c"; dns = [ "label-hallway" ]; };
    canon-hallway   = { ip = "10.255.100.236"; mac = "6c:3c:7c:13:0c:cc"; dns = [ "canon-hallway" ]; };

    # --- Smart home ---
    main-bridge          = { ip = "10.255.101.240"; mac = "00:17:88:a7:27:9c"; };
    secondary-bridge     = { ip = "10.255.101.239"; mac = "ec:b5:fa:a5:8e:7d"; };
    office-ian-plug      = { ip = "10.255.100.231"; mac = "6c:5a:b0:2e:79:70"; };
    office-martin-plug   = { ip = "10.255.100.232"; mac = "54:af:97:1d:72:c4"; };
    livingroom-heater-plug = { ip = "10.255.100.233"; mac = "54:af:97:1d:63:6c"; };
    terrace-laundry-plug = { ip = "10.255.100.234"; mac = "54:af:97:1d:55:e6"; };
    terrace-fridge-plug  = { ip = "10.255.100.235"; mac = "54:af:97:1d:59:d8"; };

    # --- Cameras (VLAN 200, managed by UNVR/Protect) ---
    camera-livingroom        = { ip = "10.255.200.1";  mac = "f4:e2:c6:0e:5f:06"; };
    camera-kitchen           = { ip = "10.255.200.2";  mac = "f4:e2:c6:7c:03:be"; };
    camera-terrace-east      = { ip = "10.255.200.3";  mac = "d0:21:f9:97:a6:7d"; };
    camera-terrace-indoor    = { ip = "10.255.200.4";  mac = "f4:e2:c6:0f:f3:cc"; };
    camera-hallway-entry     = { ip = "10.255.200.5";  mac = "f4:e2:c6:70:3f:fa"; };
    camera-terrace-door      = { ip = "10.255.200.7";  mac = "f4:e2:c6:77:99:d6"; };
    camera-terrace-west-east = { ip = "10.255.200.8";  mac = "f4:e2:c6:77:99:d7"; };
    camera-terrace-west-south = { ip = "10.255.200.9"; mac = "f4:e2:c6:77:98:1c"; };
    camera-hallway-kitchen   = { ip = "10.255.200.10"; mac = "f4:e2:c6:0e:61:6d"; };
    camera-hallway-office    = { ip = "10.255.200.13"; mac = "f4:e2:c6:0e:5d:ce"; };
    camera-office            = { ip = "10.255.200.14"; mac = "f4:e2:c6:0e:5d:9f"; };

    # --- Movistar STB ---
    livingroom-movistar-stb = { ip = "10.255.101.201"; mac = "e8:b2:fe:06:a1:28"; };

    # --- WireGuard (10.100.0.0/24) ---
    wg-goose     = { ip = "10.100.0.1"; dns = [ "wg-goose" ]; };
    wg-peer-2    = { ip = "10.100.0.2"; };
    wg-peer-3    = { ip = "10.100.0.3"; };
    wg-peer-4    = { ip = "10.100.0.4"; };
    wg-peer-5    = { ip = "10.100.0.5"; };
    wg-peer-6    = { ip = "10.100.0.6"; };
    wg-peer-7    = { ip = "10.100.0.7"; };
    wg-khosu     = { ip = "10.100.0.8"; dns = [ "wg-khosu" ]; };
    wg-ians-iphone = { ip = "10.100.0.9"; dns = [ "wg-ians-iphone" ]; };
    wg-anubis      = { ip = "10.100.0.10"; dns = [ "wg-anubis" ]; };

    # --- Kubernetes ---
    k8s-master-00 = { ip = "10.255.101.234"; ip6 = "${ulaPrefix}:101::234"; mac = "d8:43:ae:1a:1a:5c"; };
    k8s-worker-00 = { ip = "10.255.101.235"; ip6 = "${ulaPrefix}:101::235"; mac = "d8:43:ae:18:b3:bd"; };
    k8s-worker-01 = { ip = "10.255.101.236"; ip6 = "${ulaPrefix}:101::236"; mac = "d8:43:ae:18:b3:c5"; };
    k8s-worker-02 = { ip = "10.255.101.237"; ip6 = "${ulaPrefix}:101::237"; mac = "d8:43:ae:18:b3:6d"; };
    k8s-api       = { ip = "10.255.240.1"; };  # k8s API service ClusterIP
  };

  # Extra DNS aliases (different domain or pointing to existing host IPs)
  extraDns = [
    { name = "k8s-master.local";    ip = hosts.k8s-master-00.ip; }
    { name = "k8s-master-00.local"; ip = hosts.k8s-master-00.ip; }
    { name = "k8s-worker-00.local"; ip = hosts.k8s-worker-00.ip; }
    { name = "k8s-worker-01.local"; ip = hosts.k8s-worker-01.ip; }
    { name = "k8s-worker-02.local"; ip = hosts.k8s-worker-02.ip; }
    { name = "cloudkey";   ip = hosts.pakhet.ip; }
    { name = "fatty-ipmi"; ip = hosts.pakhet.ip; }
    { name = "goose-ipmi"; ip = hosts.pakhet.ip; }
    { name = "grafana";    ip = hosts.pakhet.ip; }
    { name = "printcam";   ip = hosts.pakhet.ip; }
    { name = "obico";      ip = hosts.pakhet.ip; }
  ];

  # --- Helper functions ---

  # host's DNS names: uses `dns` attr if present, otherwise [ attrName ]
  hostDnsNames = name: host:
    if host ? dns then host.dns else [ name ];

  # Qualify a DNS name: if it already contains a dot, use as-is; otherwise append domain
  qualify = n:
    if lib.hasInfix "." n then n
    else "${n}.${domain}";

  # Forward DNS: A records for unbound local-data
  forwardDns = lib.flatten (lib.mapAttrsToList (name: host:
    let names = hostDnsNames name host;
    in map (n: ''"${qualify n}. IN A ${host.ip}"'') names
  ) hosts)
  ++ map (e: ''"${e.name}. IN A ${e.ip}"'') extraDns;

  # Reverse DNS: PTR records for unbound local-data
  reverseDns = lib.mapAttrsToList (name: host:
    let
      dnsName = builtins.head (hostDnsNames name host);
      fqdn = qualify dnsName;
      parts = lib.splitString "." host.ip;
      rev = lib.concatStringsSep "." (lib.reverseList parts);
    in ''"${rev}.in-addr.arpa. IN PTR ${fqdn}."''
  ) hosts;

  # Reverse zones needed for unbound
  reverseZones = lib.unique (lib.mapAttrsToList (_: host:
    let
      parts = lib.splitString "." host.ip;
      rev3 = lib.concatStringsSep "." (lib.reverseList (lib.take 3 parts));
    in ''"${rev3}.in-addr.arpa." static''
  ) hosts);

  # IPv6 ULA: AAAA records for hosts with ip6
  hostsWithIp6 = lib.filterAttrs (_: host: host ? ip6) hosts;

  forwardDns6 = lib.optionals enableIPv6ULA (lib.flatten (lib.mapAttrsToList (name: host:
    let names = hostDnsNames name host;
    in map (n: ''"${qualify n}. IN AAAA ${host.ip6}"'') names
  ) hostsWithIp6));

  reverseDns6 = lib.optionals enableIPv6ULA (lib.mapAttrsToList (name: host:
    let
      dnsName = builtins.head (hostDnsNames name host);
      fqdn = qualify dnsName;
      expanded = expandIp6 host.ip6;
      nibbles = lib.stringToCharacters (lib.replaceStrings [":"] [""] expanded);
      rev = lib.concatStringsSep "." (lib.reverseList nibbles);
    in ''"${rev}.ip6.arpa. IN PTR ${fqdn}."''
  ) hostsWithIp6);

  # Expand :: in IPv6 address to full 32-nibble form
  expandIp6 = addr:
    let
      halves = lib.splitString "::" addr;
      left = if builtins.head halves == "" then [] else lib.splitString ":" (builtins.head halves);
      right = if lib.length halves > 1 && builtins.elemAt halves 1 != "" then lib.splitString ":" (builtins.elemAt halves 1) else [];
      missing = 8 - lib.length left - lib.length right;
      zeros = lib.genList (_: "0000") missing;
      pad = s: let len = builtins.stringLength s; in
        if len >= 4 then s
        else pad ("0" + s);
      allGroups = map pad (left ++ zeros ++ right);
    in lib.concatStringsSep ":" allGroups;

  reverseZones6 = lib.optionals enableIPv6ULA (lib.unique (lib.mapAttrsToList (_: host:
    let
      expanded = expandIp6 host.ip6;
      nibbles = lib.stringToCharacters (lib.replaceStrings [":"] [""] expanded);
      # /48 reverse zone = first 12 nibbles
      rev12 = lib.concatStringsSep "." (lib.reverseList (lib.take 12 nibbles));
    in ''"${rev12}.ip6.arpa." static''
  ) hostsWithIp6));

  # DHCPv6 reservations: hosts with mac and ip6
  dhcp6Reservations = lib.optionals enableIPv6ULA (lib.mapAttrsToList (name: host: {
    hostname = name;
    hw-address = host.mac;
    ip-addresses = [ host.ip6 ];
  }) (lib.filterAttrs (_: host: host ? mac && host ? ip6) hosts));

  # DHCP reservations: only hosts with `mac`
  dhcpReservations = lib.mapAttrsToList (name: host: {
    hostname = name;
    hw-address = host.mac;
    ip-address = host.ip;
  }) (lib.filterAttrs (_: host: host ? mac) hosts);

  # DNAT rule generation from host registry
  hostsWithDnat = lib.filterAttrs (_: host: host ? dnat && host.dnat != []) hosts;

  mkDnatRules = { extIfaces, oif ? "wired" }:
    let
      hostRules = lib.mapAttrsToList (name: host:
        let
          byProto = lib.groupBy (r: r.proto) host.dnat;
        in lib.concatLists (lib.mapAttrsToList (proto: rules:
          let
            batch = lib.filter (r: !(r ? toPort)) rules;
            remap = lib.filter (r: r ? toPort) rules;
            portSet = ports:
              "{ ${lib.concatMapStringsSep ", " (p: toString p) ports} }";
            batchPorts = map (r: r.port) batch;
          in
          (lib.optionals (batch != []) [{
            forward = "meta iifname ${extIfaces} oifname \"${oif}\" ip daddr ${host.ip} ${proto} dport ${portSet batchPorts} ct state new counter accept comment \"dnat ${name} ${proto}\"";
            prerouting = "meta iifname ${extIfaces} ${proto} dport ${portSet batchPorts} counter dnat ${host.ip} comment \"dnat ${name} ${proto}\"";
            preroutingLocal = "${proto} dport ${portSet batchPorts} fib daddr type local counter dnat ip to ${host.ip} comment \"dnat-local ${name} ${proto}\"";
          }])
          ++ map (r: {
            forward = "meta iifname ${extIfaces} oifname \"${oif}\" ip daddr ${host.ip} ${proto} dport ${toString r.toPort} ct state new counter accept comment \"dnat ${name} ${proto}:${toString r.port}->${toString r.toPort}\"";
            prerouting = "meta iifname ${extIfaces} ${proto} dport ${toString r.port} counter dnat ${host.ip}:${toString r.toPort} comment \"dnat ${name} ${proto}:${toString r.port}->${toString r.toPort}\"";
            preroutingLocal = "${proto} dport ${toString r.port} fib daddr type local counter dnat ip to ${host.ip}:${toString r.toPort} comment \"dnat-local ${name} ${proto}:${toString r.port}->${toString r.toPort}\"";
          }) remap
        ) byProto)
      ) hostsWithDnat;
      allRules = lib.flatten hostRules;
    in {
      forward = lib.concatMapStringsSep "\n" (r: r.forward) allRules;
      prerouting = lib.concatMapStringsSep "\n" (r: r.prerouting) allRules;
      preroutingLocal = lib.concatMapStringsSep "\n" (r: r.preroutingLocal) allRules;
    };

  mailDomains = [
    "shouldidrink.today"
    "unixpimps.net"
    "nordic-t.me"
  ];

in {
  inherit domain hosts extraDns mailDomains mkDnatRules;
  inherit enableIPv6ULA ulaPrefix;
  inherit forwardDns reverseDns reverseZones dhcpReservations;
  inherit forwardDns6 reverseDns6 reverseZones6 dhcp6Reservations;
}
