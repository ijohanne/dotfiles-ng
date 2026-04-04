{ config, lib, pkgs, ... }:

let
  cfg = config.services.smsGatewayClient;

  package = pkgs.writeShellApplication {
    name = cfg.commandName;
    runtimeInputs = with pkgs; [ bash curl jq ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      if [[ $# -ne 1 ]]; then
        echo "Need text message as argument"
        exit 1
      fi

      source ${lib.escapeShellArg cfg.envFile}

      message="$1"

      sid=$(curl -sf "http://$SMS_IP/ubus" -X POST \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"call\",\"params\":[\"00000000000000000000000000000000\",\"session\",\"login\",{\"username\":\"$SMS_USER\",\"password\":\"$SMS_PASSWORD\"}]}" \
        | jq -re '.result[1].ubus_rpc_session')

      IFS=',' read -ra numbers <<< "$SMS_TARGET_NUMBER"
      for number in "''${numbers[@]}"; do
        curl -sf "http://$SMS_IP/api/messages/actions/send" -X POST \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $sid" \
          -d "{\"data\":{\"modem\":\"$SMS_MODEM\",\"number\":\"$number\",\"message\":\"$message\"}}"
        echo ""
      done
    '';
  };
in
{
  options.services.smsGatewayClient = {
    enable = lib.mkEnableOption "SMS gateway client command";

    commandName = lib.mkOption {
      type = lib.types.str;
      default = "sms";
      description = "Command name to install for the SMS gateway client.";
    };

    envFile = lib.mkOption {
      type = lib.types.path;
      description = "Shell env file containing SMS gateway connection variables.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
  };
}
