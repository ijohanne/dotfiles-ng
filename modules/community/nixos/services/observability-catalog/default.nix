{ config, lib, pkgs, ... }:
let
  cfg = config.observability;
  settings = pkgs.writeText "observability-catalog.json" (builtins.toJSON {
    inherit (cfg) services grafanaUrl;
  });
in
{
  options.observability = {
    grafanaUrl = lib.mkOption { type = lib.types.str; };
    services = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          dashboards = lib.mkOption { type = lib.types.nullOr lib.types.path; default = null; };
          skills = lib.mkOption { type = lib.types.listOf lib.types.path; default = [ ]; };
          jobs = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ ]; };
        };
      });
    };
    skillsDirectory = lib.mkOption {
      type = lib.types.path;
      readOnly = true;
      default = pkgs.runCommand "observability-skills" { nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pyyaml ])) ]; } ''
        python3 ${./build-skills.py} ${settings} "$out"
      '';
    };
  };
  config.services.grafana.provision.dashboards.settings.providers = lib.mapAttrsToList
    (name: entry: { inherit name; options.path = entry.dashboards; })
    (lib.filterAttrs (_: entry: entry.dashboards != null) cfg.services);
}
