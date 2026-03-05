{ ... }:

{
  #services.prometheus-tplink-p110-exporter = {
  #  enable = true;
  #  enableLocalScraping = true;
  #  secrets via sops:
  #    config.sops.secrets.tplink_username.path
  #    config.sops.secrets.tplink_password.path
  #  hosts = [ "10.255.100.234" "10.255.100.235" ];
  #};
}
