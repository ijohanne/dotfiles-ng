{ ... }:

{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    reflector = true;
    ipv6 = false;
    allowPointToPoint = true;
    cacheEntriesMax = 0;
    allowInterfaces = [
      "wifi"
      "wired"
      "camera"
      "mgnt"
    ];
  };
}
