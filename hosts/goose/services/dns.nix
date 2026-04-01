{ pkgs, network, lib, ... }:

let
  hickory-dns = pkgs.rustPlatform.buildRustPackage rec {
    pname = "hickory-dns";
    version = "0.26.0-beta.2";
    src = pkgs.fetchFromGitHub {
      owner = "hickory-dns";
      repo = "hickory-dns";
      rev = "v${version}";
      hash = "sha256-7kra6MbLcv0P6iiUJ+hQ0ezqgXh/1KskCrZvFYDqiXQ=";
    };
    cargoHash = "sha256-FfckN+qhSqbc8jnL0xThdAMQEgluocSY1ksEyT8rFFY=";
    buildAndTestSubdir = "bin";
    buildFeatures = [ "sqlite" "resolver" "recursor" "prometheus-metrics" ];
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl pkgs.sqlite ];
    doCheck = false;
    meta.mainProgram = "hickory-dns";
  };

  dataDir = "/var/lib/hickory-dns";

  hostDnsNames = name: host:
    if host ? dns then host.dns else [ name ];

  # Only names without dots belong in the est.unixpimps.net zone.
  # Names with dots (e.g. "k8s-master.local") are in other domains
  # and cannot be served from an authoritative zone without creating
  # a zone for that domain.
  isInZone = name: !(lib.hasInfix "." name);

  mkSoa = zone: ''
    $ORIGIN ${zone}.
    $TTL 3600
    @ IN SOA ns1.${network.domain}. admin.unixpimps.net. (
        1       ; serial
        3600    ; refresh
        900     ; retry
        604800  ; expire
        300     ; minimum
    )
    @ IN NS ns1.${network.domain}.
  '';

  # --- Forward zone (est.unixpimps.net) ---

  hostARecords = lib.flatten (lib.mapAttrsToList (name: host:
    let names = builtins.filter isInZone (hostDnsNames name host);
    in map (n: "${n} IN A ${host.ip}") names
  ) network.hosts);

  extraARecords = map (e: "${e.name} IN A ${e.ip}")
    (builtins.filter (e: isInZone e.name) network.extraDns);

  hostsWithIp6 = lib.filterAttrs (_: host: host ? ip6) network.hosts;

  hostAAAARecords = lib.optionals network.enableIPv6ULA (lib.flatten (
    lib.mapAttrsToList (name: host:
      let names = builtins.filter isInZone (hostDnsNames name host);
      in map (n: "${n} IN AAAA ${host.ip6}") names
    ) hostsWithIp6));

  forwardZoneContent =
    mkSoa network.domain
    + "ns1 IN A ${network.hosts.goose.ips.mgnt}\n"
    + lib.concatStringsSep "\n" (hostARecords ++ extraARecords ++ hostAAAARecords)
    + "\n";

  # --- DDNS zones (empty, populated by Kea D2) ---

  ddnsZoneContent =
    mkSoa "dhcp.${network.domain}"
    + "ns1.${network.domain}. IN A ${network.hosts.goose.ips.mgnt}\n";

  guestZoneContent =
    mkSoa "guest.${network.domain}"
    + "ns1.${network.domain}. IN A ${network.hosts.goose.ips.mgnt}\n";

  # --- Reverse zones ---

  allHostEntries = lib.mapAttrsToList (name: host: {
    dnsName = builtins.head (hostDnsNames name host);
    inherit (host) ip;
  }) network.hosts;

  hostsBySubnet = lib.groupBy (h:
    let parts = lib.splitString "." h.ip;
    in "${builtins.elemAt parts 0}.${builtins.elemAt parts 1}.${builtins.elemAt parts 2}"
  ) allHostEntries;

  mkReverseZone = subnet: entries:
    let
      parts = lib.splitString "." subnet;
      revSubnet = "${builtins.elemAt parts 2}.${builtins.elemAt parts 1}.${builtins.elemAt parts 0}";
      zoneName = "${revSubnet}.in-addr.arpa";
      fqdn = name:
        if lib.hasInfix "." name then "${name}."
        else "${name}.${network.domain}.";
      records = map (h:
        let lastOctet = lib.last (lib.splitString "." h.ip);
        in "${lastOctet} IN PTR ${fqdn h.dnsName}"
      ) entries;
    in {
      name = zoneName;
      content = mkSoa zoneName
        + "ns1.${network.domain}. IN A ${network.hosts.goose.ips.mgnt}\n"
        + lib.concatStringsSep "\n" records + "\n";
    };

  reverseZones = lib.mapAttrsToList mkReverseZone hostsBySubnet;

  # --- Zone file derivations ---

  forwardZoneFile = pkgs.writeText "est.unixpimps.net.zone" forwardZoneContent;
  ddnsZoneFile = pkgs.writeText "dhcp.est.unixpimps.net.zone" ddnsZoneContent;
  guestZoneFile = pkgs.writeText "guest.est.unixpimps.net.zone" guestZoneContent;

  reverseZoneFilesByName = builtins.listToAttrs (map (z: {
    name = z.name;
    value = pkgs.writeText "${z.name}.zone" z.content;
  }) reverseZones);

  # --- Listen addresses (explicit per issue comment re: hickory-dns#3401) ---

  listenAddrsIpv4 = [
    "127.0.0.1"
    network.hosts.goose.ips.wifi
    network.hosts.goose.ips.wired
    network.hosts.goose.ips.guest
    network.hosts.goose.ips.camera
    network.hosts.goose.ips.mgnt
  ];

  listenAddrsIpv6 = lib.optionals network.enableIPv6ULA [
    "::1"
    network.hosts.goose.ip6s.wifi
    network.hosts.goose.ip6s.wired
    network.hosts.goose.ip6s.mgnt
  ];

  # --- TOML helpers ---

  toTomlStrArray = items: "[${lib.concatMapStringsSep ", " (i: ''"${i}"'') items}]";

  reverseZoneToml = lib.concatMapStringsSep "\n" (z: ''
    [[zones]]
    zone = "${z.name}."
    zone_type = "Primary"
    file = "${reverseZoneFilesByName.${z.name}}"
  '') reverseZones;

  rootHints = "${pkgs.dns-root-data}/share/dns/root.hints";

  allowNetworks = [ "10.0.0.0/8" "127.0.0.0/8" ]
    ++ lib.optionals network.enableIPv6ULA [ "fc00::/7" "::1/128" ];

  configContent = ''
    listen_addrs_ipv4 = ${toTomlStrArray listenAddrsIpv4}
    listen_addrs_ipv6 = ${toTomlStrArray listenAddrsIpv6}
    listen_port = 53
    directory = "${dataDir}"
    tcp_request_timeout = 5
    allow_networks = ${toTomlStrArray allowNetworks}
    prometheus_listen_addr = "127.0.0.1:9153"

    [[zones]]
    zone = "${network.domain}."
    zone_type = "Primary"
    file = "${forwardZoneFile}"

    [[zones]]
    zone = "dhcp.${network.domain}."
    zone_type = "Primary"

    [zones.stores]
    type = "sqlite"
    zone_file_path = "${ddnsZoneFile}"
    journal_file_path = "${dataDir}/dhcp.${network.domain}.jrnl"
    allow_update = true

    [[zones]]
    zone = "guest.${network.domain}."
    zone_type = "Primary"

    [zones.stores]
    type = "sqlite"
    zone_file_path = "${guestZoneFile}"
    journal_file_path = "${dataDir}/guest.${network.domain}.jrnl"
    allow_update = true

    ${reverseZoneToml}

    [[zones]]
    zone = "."
    zone_type = "External"

    [zones.stores]
    type = "recursor"
    roots = "${rootHints}"
    ns_cache_size = 1024
    record_cache_size = 1048576
  '';

  configFile = pkgs.writeText "hickory-dns.toml" configContent;

in
{
  users.users.hickory-dns = {
    isSystemUser = true;
    group = "hickory-dns";
  };
  users.groups.hickory-dns = {};

  systemd.services.hickory-dns = {
    description = "hickory-dns DNS server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${hickory-dns}/bin/hickory-dns -c ${configFile}";
      User = "hickory-dns";
      Group = "hickory-dns";
      StateDirectory = "hickory-dns";
      AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ dataDir ];
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
    };
  };
}
