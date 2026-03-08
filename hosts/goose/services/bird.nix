{ interfaces, network, ... }:

{ pkgs, ... }:

{
  services.bird = {
    enable = true;
    package = pkgs.bird2;
    config = ''
      define OWNAS = 65000;
      define OWNIP = ${network.hosts.goose.ips.mgnt};

      router id OWNIP;

      protocol device {
        scan time 10;
      }

      protocol kernel {
        ipv4 {
          import none;
          export filter {
            if source = RTS_STATIC then reject;
            krt_prefsrc = OWNIP;
            accept;
          };
        };
        persist;
      }

      template bgp K8S {
        local as OWNAS;

        ipv4 {
          import filter {
            if ( net ~ [10.255.240.0/24+] ) then accept;
            reject;
          };

          export filter{
            reject;
          };
        };
      };

      protocol bgp k8s_0 from K8S { neighbor ${network.hosts.k8s-master-00.ip} as 65001; };
      protocol bgp k8s_1 from K8S { neighbor ${network.hosts.k8s-worker-00.ip} as 65001; };
      protocol bgp k8s_2 from K8S { neighbor ${network.hosts.k8s-worker-01.ip} as 65001; };
      protocol bgp k8s_3 from K8S { neighbor ${network.hosts.k8s-worker-02.ip} as 65001; };

      protocol rip movistar {
        ipv4 {
          import filter {
            if ( net ~ [172.16.0.0/12+, 10.0.0.0/8+] ) then accept;
            reject;
          };
          export none;
        };
        interface "${interfaces.external}" {
          passive;
          authentication none;
        };
      }
    '';
  };
}
