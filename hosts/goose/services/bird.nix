{ pkgs, ... }:

{
  services.bird = {
    enable = true;
    package = pkgs.bird2;
    config = ''
      define OWNAS = 65000;
      define OWNIP = 10.255.254.254;

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

      protocol bgp k8s_0 from K8S { neighbor 10.255.101.234 as 65001; };
      protocol bgp k8s_1 from K8S { neighbor 10.255.101.235 as 65001; };
      protocol bgp k8s_2 from K8S { neighbor 10.255.101.236 as 65001; };
      protocol bgp k8s_3 from K8S { neighbor 10.255.101.237 as 65001; };
    '';
  };
}
