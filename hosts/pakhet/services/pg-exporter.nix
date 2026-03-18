{ config, ... }:

{
  sops.secrets.pg-exporter-env = { };

  services.pg-exporter = {
    enable = true;
    port = 9630;
    listenAddress = "0.0.0.0";
    autoDiscovery = true;
    environmentFile = config.sops.secrets.pg-exporter-env.path;

    defaultCollectors = true;
    disabledCollectors = [
      "pgbouncer_list"
      "pgbouncer_database"
      "pgbouncer_stat"
      "pgbouncer_pool"
      "pg_tsdb_hypertable"
      "pg_citus"
      "pg_recv"
      "pg_sub"
      "pg_origin"
      "pg_pubrel"
      "pg_subrel"
      "pg_sync_standby"
      "pg_downstream"
      "pg_heartbeat"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 9630 ];
}
