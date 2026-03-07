{
  services.perlpimpnet = {
    enable = true;
    domain = "perlpimp.net";
    acme = true;
    extraDomains = [ "www.perlpimp.net" ];
    analytics.plausible.enable = true;
  };
}
