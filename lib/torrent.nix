{
  protonGateway = "10.2.0.1";
  wgIP          = "10.2.0.2";

  backhaulIP    = "10.100.0.10";
  backhaulAllowedRanges = [
    "10.255.0.0/16"
    "10.100.0.0/24"
  ];

  domain        = "wg-anubis.est.unixpimps.net";
  acmeEmail     = "sysops@unixpimps.net";
}
