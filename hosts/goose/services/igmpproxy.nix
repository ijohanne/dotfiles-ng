{ interfaces, ... }:

{ pkgs, ... }:

let
  confFile = pkgs.writeText "igmpproxy.conf" ''
    phyint ${interfaces.external} upstream ratelimit 0 threshold 1
      altnet 172.26.0.0/17
      altnet 172.23.0.0/17
    phyint wired downstream ratelimit 0 threshold 1
    phyint wifi downstream ratelimit 0 threshold 1
    phyint guest disabled
    phyint camera disabled
    phyint mgnt disabled
    phyint lo disabled
  '';
in
{
  systemd.services.igmpproxy = {
    description = "igmpproxy Multicast Router Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "@${pkgs.igmpproxy}/bin/igmpproxy igmpproxy -n ${confFile}";
      Restart = "always";
      User = "root";
      CapabilityBoundingSet = "cap_net_admin cap_net_broadcast cap_net_raw";
    };
  };
}
