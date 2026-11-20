{ lib, pkgs, ... }:

let
  version = "1.30.7";
in
{
  services.nginx.package =
    if lib.versionAtLeast pkgs.nginxStable.version version then pkgs.nginxStable
    else
      pkgs.nginxStable.overrideAttrs {
        inherit version;
        nginxVersion = version;
        src = pkgs.fetchurl {
          url = "https://nginx.org/download/nginx-${version}.tar.gz";
          hash = "sha256-JWW1yDcFDpWPcPsPc8SOK8pFQq00n9NW9G+wxyYQvG4=";
        };
      };
}
