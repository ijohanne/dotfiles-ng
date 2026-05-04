{ pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    extensions = ps: [ ps.postgis ];
    settings = {
      max_connections = 200;
      superuser_reserved_connections = 10;
    };
  };
}
