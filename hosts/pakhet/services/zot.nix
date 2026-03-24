{ config, ... }:

{
  sops.secrets.zot_admin_password = {
    mode = "0400";
    owner = "zot";
    group = "zot";
  };

  sops.secrets.zot_uptimeplaza_password = {
    mode = "0400";
    owner = "zot";
    group = "zot";
  };

  services.zot = {
    enable = true;
    settings.http.port = "5000";
    auth.users = {
      admin = {
        passwordFile = config.sops.secrets.zot_admin_password.path;
        admin = true;
      };
      uptimeplaza = {
        passwordFile = config.sops.secrets.zot_uptimeplaza_password.path;
      };
    };
    accessControl.repositories."uptimeplaza/**" = {
      policies = [{
        users = [ "uptimeplaza" ];
        actions = [ "read" "create" "update" "delete" ];
      }];
    };
    retention.policies = [
      {
        repositories = [ "uptimeplaza/**" ];
        deleteReferrers = true;
        deleteUntagged = true;
        keepTags = [
          { patterns = [ "latest" ]; }
          { pushedWithin = "168h"; }
        ];
      }
    ];
    nginx = {
      enable = true;
      domain = "registry.unixpimps.net";
      acmeDns01 = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
