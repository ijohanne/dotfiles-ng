{ config, ... }:

{
  imports = [ ./postfix.nix ];

  sops.secrets.relay_sasl_password = { };
}
