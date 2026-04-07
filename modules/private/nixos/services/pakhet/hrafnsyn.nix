{ config, inputs, network, pkgs, ... }:

let
  domain = "hrafnsyn.unixpimps.net";
  nurPackages = inputs.ijohanne-nur.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  sops.secrets.hrafnsyn_secret_key_base = {
    mode = "0400";
    owner = "hrafnsyn";
    group = "hrafnsyn";
  };

  sops.secrets.hrafnsyn_ij_password_hash = {
    mode = "0400";
    owner = "hrafnsyn";
    group = "hrafnsyn";
  };

  services.hrafnsyn = {
    enable = true;
    package = nurPackages.hrafnsyn;
    aircraftDbPackage = nurPackages.hrafnsyn-aircraft-db;

    host = domain;
    port = 4020;
    metricsPort = 4022;
    listenAddress = "0.0.0.0";
    autoMigrate = true;
    publicReadonly = false;

    secretKeyBaseFile = config.sops.secrets.hrafnsyn_secret_key_base.path;

    database = {
      host = "/run/postgresql";
      name = "hrafnsyn";
      user = "hrafnsyn";
    };

    sources = [
      {
        id = "planes-main";
        name = "Airplane SDR";
        vehicleType = "plane";
        adapter = "dump1090";
        baseUrl = "http://${network.hosts.chronos-wired.ip}";
        pollIntervalMs = 1000;
      }
      {
        id = "boats-main";
        name = "Boat SDR";
        vehicleType = "vessel";
        adapter = "ais_catcher";
        baseUrl = "http://${network.hosts.chronos-wired.ip}:8100";
        pollIntervalMs = 2500;
      }
    ];

    bootstrapAdminEmail = "ij@perlpimp.net";
    bootstrapAdminPasswordHashFile = config.sops.secrets.hrafnsyn_ij_password_hash.path;
    extraEnv.BOOTSTRAP_ADMIN_USERNAME = "ij";

    nginxHelper = {
      enable = true;
      domain = domain;
      enableACME = true;
    };
  };
}
