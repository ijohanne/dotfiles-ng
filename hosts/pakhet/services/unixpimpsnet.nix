{
  services.unixpimpsnet = {
    enable = true;
    domain = "unixpimps.net";
    acme = true;
    extraDomains = [ "www.unixpimps.net" ];
    analytics.plausible.enable = true;
  };
}
