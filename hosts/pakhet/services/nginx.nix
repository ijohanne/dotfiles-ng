{ config, pkgs, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "sysops@unixpimps.net";
    defaults = {
      dnsProvider = "cloudflare";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets.cloudflare_api_key.path;
    };
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    statusPage = true;
    additionalModules = [
      pkgs.nginxModules.geoip2
    ];
    appendHttpConfig = ''
      geoip2 /var/lib/geoip-databases/GeoLite2-Country.mmdb {
        auto_reload 5m;
        $geoip2_metadata_country_build metadata build_epoch;
        $geoip2_data_country_code country iso_code;
        $geoip2_data_country_name country names en;
        $geoip2_data_continent_code continent code;
        $geoip2_data_continent_name continent names en;
      }

      geoip2 /var/lib/geoip-databases/GeoLite2-City.mmdb {
        auto_reload 5m;
        $geoip2_data_city_name city names en;
        $geoip2_data_lat location latitude;
        $geoip2_data_lon location longitude;
      }

      geoip2 /var/lib/geoip-databases/GeoLite2-ASN.mmdb {
        auto_reload 5m;
        $geoip2_data_asn autonomous_system_number;
        $geoip2_data_asorg autonomous_system_organization;
      }

      fastcgi_param MM_CONTINENT_CODE $geoip2_data_continent_code;
      fastcgi_param MM_CONTINENT_NAME $geoip2_data_continent_name;
      fastcgi_param MM_COUNTRY_CODE $geoip2_data_country_code;
      fastcgi_param MM_COUNTRY_NAME $geoip2_data_country_name;
      fastcgi_param MM_CITY_NAME $geoip2_data_city_name;
      fastcgi_param MM_LATITUDE $geoip2_data_lat;
      fastcgi_param MM_LONGITUDE $geoip2_data_lon;
      fastcgi_param MM_ISP $geoip2_data_asorg;
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 3002 ];
}
