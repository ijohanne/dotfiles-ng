{ config, inputs, network, modules, pkgs, ... }:
let
  unstable = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    modules.public.nixos.services.prometheusMcp
    modules.public.nixos.services.observabilityCatalog
  ];
  sops.secrets.observability_mcp_client_secret.restartUnits = [ "prometheus-mcp.service" ];
  services.prometheusMcp = {
    enable = true;
    package = unstable.callPackage ../../../../community/packages/prometheus-mcp {
      buildGoModule = unstable.buildGoModule.override { go = unstable.go_1_27; };
    };
    listenAddress = "${network.hosts.goose.ips.mgnt}:9002";
    resource = "https://prometheus.${network.domain}";
    issuer = "https://auth.${network.domain}";
    introspectionUrl = "https://auth.${network.domain}/api/oidc/introspection";
    clientSecretFile = config.sops.secrets.observability_mcp_client_secret.path;
    skillsDirectory = config.observability.skillsDirectory;
  };
  services.prometheus.scrapeConfigs = [{
    job_name = "prometheus-mcp";
    static_configs = [{ targets = [ "${network.hosts.goose.ips.mgnt}:9002" ]; }];
  }];
}
